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

    perInstance =
      {
        roles,
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
            clientMachines = lib.attrNames (roles.client.machines or { });
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

            users.groups.nix = { };
            users.users.nix = {
              isSystemUser = true;
              group = "nix";
              home = "/var/empty";
              createHome = false;
              shell = pkgs.bashInteractive;
              openssh.authorizedKeys.keys = map (
                machine:
                clanLib.getPublicValue {
                  flake = config.clan.core.settings.directory;
                  inherit machine;
                  generator = "remote-builder";
                  file = "id_ed25519.pub";
                }
              ) clientMachines;
            };

            nix.settings.trusted-users = lib.mkAfter [ "nix" ];
          };
      };
  };

  roles.client = {
    description = "machine offloading nix builds to remote builder";

    perInstance =
      {
        roles,
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
            builderMachines = lib.attrNames (roles.builder.machines or { });
            builderName = lib.head builderMachines;
          in
          {
            nix.distributedBuilds = lib.mkDefault true;

            clan.core.vars.generators.remote-builder = {
              files."id_ed25519" = { };
              files."id_ed25519.pub".secret = false;
              runtimeInputs = [ pkgs.openssh ];
              script = ''
                ssh-keygen -t ed25519 -N "" -f "$out/id_ed25519" -q
              '';
            };

            nix.buildMachines = [
              {
                hostName = "${builderName}.${config.clan.core.settings.domain}";
                sshUser = "nix";
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
              }
            ];
          };
      };
  };
}
