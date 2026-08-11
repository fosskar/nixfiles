_: {
  flake.modules."clan.service".remote-builder =
    { clanLib, ... }:
    {
      manifest.name = "remote-builder";
      manifest.description = "nix remote build server/client wiring";
      manifest.readme = builtins.readFile ./README.md;
      manifest.categories = [ "Developer Tools" ];

      roles.builder = {
        description = "remote nix builder host";

        interface =
          { lib, ... }:
          {
            options = {
              extraClientKeys = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "ssh pubkeys of non-clan clients allowed to offload builds";
              };
              maxJobs = lib.mkOption {
                type = lib.types.ints.positive;
                default = 8;
                description = "parallel builds on this builder; also advertised to clients";
              };
              systems = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ "x86_64-linux" ];
                description = "systems this builder builds; advertised to clients";
              };
              speedFactor = lib.mkOption {
                type = lib.types.ints.positive;
                default = 10;
                description = "relative builder speed advertised to clients";
              };
              supportedFeatures = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [
                  "nixos-test"
                  "big-parallel"
                  "kvm"
                  "uid-range"
                  "recursive-nix"
                ];
                description = "features advertised to clients; uid-range and recursive-nix also enable the matching nix settings on the builder";
              };
              gcKeepFreeGiB = lib.mkOption {
                type = lib.types.ints.positive;
                default = 128;
                description = "free space target the hourly nix gc maintains on /nix/store";
              };
            };
          };

        perInstance =
          {
            roles,
            settings,
            ...
          }:
          {
            nixosModule =
              {
                config,
                lib,
                pkgs,
                ...
              }:
              let
                builderMachines = roles.builder.machines or { };
                # exclude builders from authorized client keys (builders not
                # offload to themselves)
                clientMachines = lib.filter (m: !(builderMachines ? ${m})) (
                  lib.attrNames (roles.client.machines or { })
                );
              in
              {
                nix.settings = {
                  max-jobs = lib.mkDefault settings.maxJobs;
                  cores = lib.mkDefault 0;
                  experimental-features = lib.mkAfter (
                    [
                      "auto-allocate-uids"
                      "cgroups"
                    ]
                    ++ lib.optional (lib.elem "recursive-nix" settings.supportedFeatures) "recursive-nix"
                  );
                  auto-allocate-uids = lib.mkDefault true;
                  # the experimental feature alone only puts uid-range derivations
                  # in a cgroup; nixbot builds untrusted PR branches, so contain
                  # every build and get an atomic kill of its process tree
                  use-cgroups = lib.mkDefault true;
                  system-features = lib.mkAfter (
                    lib.intersectLists [
                      "uid-range"
                      "recursive-nix"
                    ] settings.supportedFeatures
                  );
                };

                nix.gc = {
                  automatic = true;
                  dates = "*:45";
                  options = ''--max-freed "$((${toString settings.gcKeepFreeGiB} * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
                  randomizedDelaySec = "1800";
                };

                security.pam.loginLimits = [
                  {
                    domain = "nix-remote-builder";
                    item = "nofile";
                    type = "-";
                    value = "20480";
                  }
                ];

                services.openssh.settings.MaxStartups = 100;

                users.users.nix-remote-builder = {
                  isNormalUser = true;
                  group = "nogroup";
                  shell = pkgs.bashInteractive;
                  openssh.authorizedKeys.keys =
                    map (
                      machine:
                      ''restrict,command="nix-daemon --stdio" ${
                        clanLib.getPublicValue {
                          flake = config.clan.core.settings.directory;
                          inherit machine;
                          generator = "remote-builder";
                          file = "id_ed25519.pub";
                        }
                      }''
                    ) clientMachines
                    ++ map (key: ''restrict,command="nix-daemon --stdio" ${key}'') settings.extraClientKeys;
                };

                nix.settings.trusted-users = [ "nix-remote-builder" ];
              };
          };
      };

      roles.client = {
        description = "machine offloading nix builds to remote builder";

        perInstance =
          {
            roles,
            machine,
            ...
          }:
          {
            nixosModule =
              {
                config,
                lib,
                pkgs,
                ...
              }:
              let
                builderMachines = roles.builder.machines or { };
                builderNames = lib.attrNames builderMachines;
                # if machine is also builder, skip client config (no self-offload)
                isBuilder = builderMachines ? ${machine.name};
              in
              {
                config = lib.mkIf (!isBuilder) {
                  nix.distributedBuilds = lib.mkDefault true;

                  programs.ssh.extraConfig = lib.concatMapStrings (builderName: ''
                    Host ${builderName}.${config.clan.core.settings.domain}
                      ServerAliveInterval 30
                      ServerAliveCountMax 4
                  '') builderNames;

                  clan.core.vars.generators.remote-builder = {
                    files."id_ed25519" = { };
                    files."id_ed25519.pub".secret = false;
                    runtimeInputs = [ pkgs.openssh ];
                    script = ''
                      ssh-keygen -t ed25519 -N "" -f "$out/id_ed25519" -q
                    '';
                  };

                  nix.buildMachines = map (
                    builderName:
                    let
                      builderSettings = builderMachines.${builderName}.settings;
                    in
                    {
                      hostName = "${builderName}.${config.clan.core.settings.domain}";
                      sshUser = "nix-remote-builder";
                      inherit (builderSettings) systems speedFactor supportedFeatures;
                      inherit (builderSettings) maxJobs;
                      protocol = "ssh-ng";
                      sshKey = config.clan.core.vars.generators.remote-builder.files."id_ed25519".path;
                    }
                  ) builderNames;
                };
              };
          };
      };
    };
}
