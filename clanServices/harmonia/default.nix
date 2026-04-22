{ self }:
{ lib, ... }:
let
  inherit (lib) attrNames flip;

  varsForInstance = instanceName: pkgs: {
    clan.core.vars.generators."harmonia" = {
      share = true;
      files.sign-key.secret = true;
      files.sign-key.deploy = false;
      files.pub-key.secret = false;
      script = ''
        ${pkgs.nix}/bin/nix-store --generate-binary-cache-key ${instanceName}-1 \
          $out/sign-key \
          $out/pub-key
      '';
    };
  };
in
{
  _class = "clan.service";
  manifest.name = "harmonia";
  manifest.description = "serve local nix store as binary cache";
  manifest.readme = "harmonia server/client cache wiring";
  manifest.categories = [ "Nix Tools" ];

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
      { settings, instanceName, ... }:
      {
        nixosModule =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          {
            imports = [ self.modules.nixos.harmonia ] ++ [ (varsForInstance instanceName pkgs) ];

            clan.core.vars.generators."harmonia-private" = {
              dependencies = [ "harmonia" ];
              files.sign-key.secret = true;
              script = ''
                cp $in/harmonia/sign-key $out/sign-key
              '';
            };

            nixfiles.harmonia = {
              port = lib.mkDefault settings.port;
              signKeyPaths = [ config.clan.core.vars.generators."harmonia-private".files.sign-key.path ];
            };
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
          { config, pkgs, ... }:
          {
            imports = [ (varsForInstance instanceName pkgs) ];

            nix.settings.substituters =
              let
                inherit (config.clan.core.settings) domain;
                dotDomain = if domain != null then ".${domain}" else "";
              in
              flip map (attrNames roles.server.machines) (
                machineName:
                "http://${machineName}${dotDomain}:${
                  toString roles.server.machines.${machineName}.settings.port
                }?priority=15"
              );

            nix.settings.trusted-public-keys = [
              config.clan.core.vars.generators."harmonia".files.pub-key.value
            ];
          };
      };
  };
}
