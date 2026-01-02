{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    hasPrefix
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.nixfiles.bcachefs;
  unlockServices = lib.filter (hasPrefix "unlock-bcachefs-") (
    lib.attrNames config.boot.initrd.systemd.services
  );
in
{
  options = {
    nixfiles.bcachefs.enable = mkEnableOption "bcachefs filesystem support" // {
      default = true;
    };

    # submodule pattern: auto-apply KeyringMode=shared to all unlock-bcachefs-* services
    boot.initrd.systemd.services = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            config = mkIf (hasPrefix "unlock-bcachefs-" name) {
              serviceConfig.KeyringMode = "shared";
            };
          }
        )
      );
    };
  };

  config = mkIf cfg.enable {
    boot.supportedFilesystems = [ "bcachefs" ];
    boot.initrd.systemd.enable = true;
    environment.systemPackages = [ pkgs.bcachefs-tools ];

    boot.initrd.systemd = {
      initrdBin = [ pkgs.keyutils ];
      services.link-user-keyring = {
        description = "link user keyring to session keyring";
        wantedBy = [ "initrd.target" ];
        before = map (s: "${s}.service") unlockServices ++ [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          KeyringMode = "shared";
          ExecStart = "${pkgs.keyutils}/bin/keyctl link @u @s";
        };
      };
    };
  };
}
