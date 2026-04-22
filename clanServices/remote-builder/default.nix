{ self }:
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
            imports = [ self.modules.nixos.remoteBuilderServer ];

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
            imports = [ self.modules.nixos.remoteBuilderClient ];

            clan.core.vars.generators.remote-builder = {
              files."id_ed25519" = { };
              files."id_ed25519.pub".secret = false;
              runtimeInputs = [ pkgs.openssh ];
              script = ''
                ssh-keygen -t ed25519 -N "" -f "$out/id_ed25519" -q
              '';
            };

            nixfiles.remoteBuilderClient = {
              builderHost = lib.mkDefault "${builderName}.${config.clan.core.settings.domain}";
              sshKeyFile = lib.mkDefault config.clan.core.vars.generators.remote-builder.files."id_ed25519".path;
            };
          };
      };
  };
}
