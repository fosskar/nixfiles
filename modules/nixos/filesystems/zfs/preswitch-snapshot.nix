{
  flake.modules.nixos.zfs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # same datasets as the timed auto snapshots, so a broken migration can be
      # restored from right before the switch. zfs-auto-snapshot ignores zfs
      # errors, so a failed snapshot never blocks the switch
      system.preSwitchChecks.zfs-snapshot =
        lib.mkIf (config.boot.zfs.enabled && config.services.zfs.autoSnapshot.enable)
          ''
            case "$2" in
              switch | boot | test)
                ${
                  lib.getExe' (pkgs.zfstools.override { zfs = config.boot.zfs.package; }) "zfs-auto-snapshot"
                } ${config.services.zfs.autoSnapshot.flags} preswitch 3
                ;;
            esac
          '';
    };
}
