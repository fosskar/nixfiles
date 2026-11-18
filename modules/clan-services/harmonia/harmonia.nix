{ self, ... }:
{
  flake.modules."clan.service".harmonia =
    { clanLib, lib, ... }:
    let
      inherit (lib) attrNames flip;
      generatorName = instanceName: "harmonia-${instanceName}";
    in
    {
      manifest.name = "harmonia";
      manifest.description = "serve local nix store as binary cache";
      manifest.readme = builtins.readFile ./README.md;
      manifest.categories = [ "Development" ];

      roles.server = {
        description = "harmonia binary cache server";

        interface.options = {
          port = lib.mkOption {
            type = lib.types.port;
            default = 5000;
            description = "harmonia listen port";
          };
        };

        perInstance =
          {
            settings,
            instanceName,
            machine,
            ...
          }:
          {
            nixosModule =
              {
                config,
                pkgs,
                ...
              }:
              {
                # one key per server: a leaked key only compromises that server's cache
                clan.core.vars.generators.${generatorName instanceName} = {
                  files.sign-key.secret = true;
                  files.pub-key.secret = false;
                  runtimeInputs = [ pkgs.nix ];
                  script = ''
                    nix-store --generate-binary-cache-key ${instanceName}-${machine.name}-1 \
                      $out/sign-key \
                      $out/pub-key
                  '';
                };

                services.harmonia.cache = {
                  enable = true;
                  settings.bind = "[::]:${toString settings.port}";
                  signKeyPaths = [
                    config.clan.core.vars.generators.${generatorName instanceName}.files.sign-key.path
                  ];
                };

                nix.settings.extra-allowed-users = [ "harmonia" ];
                networking.firewall.allowedTCPPorts = [ settings.port ];
              };
          };
      };

      roles.client = {
        description = "machine using harmonia cache";

        perInstance =
          {
            instanceName,
            roles,
            ...
          }:
          {
            nixosModule =
              {
                config,
                lib,
                ...
              }:
              {
                nix.settings = lib.mkIf (!(builtins.hasAttr config.networking.hostName roles.server.machines)) {
                  substituters =
                    let
                      inherit (config.clan.core.settings) domain;
                      dotDomain = if domain != null then ".${domain}" else "";
                    in
                    flip map (attrNames roles.server.machines) (
                      machineName:
                      "http://${lib.defaultTo "${machineName}${dotDomain}" (self.lanAddress config.networking.hostName machineName)}:${
                        toString roles.server.machines.${machineName}.settings.port
                      }?priority=3"
                    );

                  trusted-public-keys = flip map (attrNames roles.server.machines) (
                    machine:
                    clanLib.getPublicValue {
                      flake = config.clan.core.settings.directory;
                      inherit machine;
                      generator = generatorName instanceName;
                      file = "pub-key";
                    }
                  );
                };
              };
          };
      };
    };
}
