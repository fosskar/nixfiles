{
  lib,
  pkgs,
  config,
  utils,
  ...
}:
let
  cfg = config.nixfiles.bcachefs;

  # bcachefs boot filesystems
  bcachefsBootFs = lib.filterAttrs (
    _: fs: fs.fsType == "bcachefs" && utils.fsNeededForBoot fs
  ) config.fileSystems;

  # unlock service names (sorted)
  unlockServices = lib.sort (a: b: a < b) (
    lib.mapAttrsToList (mp: _: "unlock-bcachefs-${utils.escapeSystemdPath mp}") bcachefsBootFs
  );

  firstUnlock = lib.head unlockServices;
  restUnlocks = lib.tail unlockServices;
in
{
  options.nixfiles.bcachefs.enable = lib.mkEnableOption "bcachefs support" // {
    default = true;
  };

  config = lib.mkIf (cfg.enable && unlockServices != [ ]) {
    boot.supportedFilesystems = [ "bcachefs" ];
    boot.initrd.systemd.enable = true;
    environment.systemPackages = [ pkgs.bcachefs-tools ];
    boot.initrd.systemd.initrdBin = [ pkgs.keyutils ];

    boot.initrd.systemd.services =
      # first unlock: real unlock + keyctl link
      {
        ${firstUnlock}.serviceConfig = {
          KeyringMode = "inherit";
          ExecStartPost = "${pkgs.keyutils}/bin/keyctl link @u @s";
        };
      }
      # rest: no-ops waiting for first
      // lib.genAttrs restUnlocks (_: {
        after = [ "${firstUnlock}.service" ];
        requires = [ "${firstUnlock}.service" ];
        serviceConfig = {
          KeyringMode = "inherit";
          ExecCondition = lib.mkForce [ "" ];
          ExecStart = lib.mkForce [
            ""
            "${pkgs.coreutils}/bin/true"
          ];
        };
      })
      # create-needed-for-boot-dirs: wait for unlock + rollback
      // {
        create-needed-for-boot-dirs = {
          serviceConfig.KeyringMode = "inherit";
          after = [
            "${firstUnlock}.service"
            "bcachefs-rollback.service"
          ];
        };
      };
  };
}
