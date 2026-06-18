_:
{ clanLib, ... }:
{
  _class = "clan.service";
  manifest.name = "remote-builder";
  manifest.description = "nix remote build server/client wiring";
  manifest.readme = "configure remote nix builder and clients with per-client ssh keys";
  manifest.categories = [ "Developer Tools" ];

  roles.builder = {
    description = "remote nix builder host";

    interface =
      { lib, ... }:
      {
        options.extraClientKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "ssh pubkeys of non-clan clients allowed to offload builds";
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
              max-jobs = lib.mkDefault 16;
              cores = lib.mkDefault 0;
              experimental-features = lib.mkAfter [
                "auto-allocate-uids"
                "cgroups"
                "recursive-nix"
              ];
              auto-allocate-uids = lib.mkDefault true;
              system-features = lib.mkAfter [
                "uid-range"
                "recursive-nix"
              ];
            };

            nix.gc = {
              automatic = true;
              dates = "*:45";
              options = ''--max-freed "$((128 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
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

              clan.core.vars.generators.remote-builder = {
                files."id_ed25519" = { };
                files."id_ed25519.pub".secret = false;
                runtimeInputs = [ pkgs.openssh ];
                script = ''
                  ssh-keygen -t ed25519 -N "" -f "$out/id_ed25519" -q
                '';
              };

              nix.buildMachines = map (builderName: {
                hostName = "${builderName}.${config.clan.core.settings.domain}";
                sshUser = "nix-remote-builder";
                systems = [ "x86_64-linux" ];
                maxJobs = 16;
                speedFactor = 10;
                protocol = "ssh-ng";
                supportedFeatures = [
                  "nixos-test"
                  "big-parallel"
                  "kvm"
                  "uid-range"
                  "recursive-nix"
                ];
                sshKey = config.clan.core.vars.generators.remote-builder.files."id_ed25519".path;
              }) builderNames;
            };
          };
      };
  };
}
