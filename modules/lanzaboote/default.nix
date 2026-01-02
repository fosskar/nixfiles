{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  cfg = config.nixfiles.lanzaboote;
in
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  options.nixfiles.lanzaboote.pkiBundle = lib.mkOption {
    type = lib.types.str;
    default = "/var/lib/sbctl";
    description = "path to secure boot key bundle";
  };

  config = {
    boot = {
      loader.systemd-boot.enable = lib.mkForce false;
      bootspec.enable = true;
      lanzaboote = {
        enable = true;
        inherit (cfg) pkiBundle;
      };
    };

    environment.systemPackages = [ pkgs.sbctl ];

    # persist secure boot keys
    nixfiles.persistence.directories = [ cfg.pkiBundle ];
  };
}
