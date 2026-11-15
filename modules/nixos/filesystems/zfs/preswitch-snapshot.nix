{
  flake.modules.nixos.zfs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      zfs = lib.getExe' config.boot.zfs.package "zfs";
      keep = 3;
    in
    {
      # same datasets as sanoid, so a broken migration can be restored from
      # right before the switch. sanoid prunes only its autosnap_ snapshots, so
      # this keeps the newest ${toString keep} itself. a failed snapshot warns
      # instead of blocking the switch
      system.preSwitchChecks.zfs-snapshot =
        lib.mkIf (config.boot.zfs.enabled && config.services.sanoid.enable)
          ''
            case "$2" in
              switch | boot | test)
                stamp=$(${pkgs.coreutils}/bin/date -u +%Y-%m-%d_%H:%M:%S)
                for dataset in ${lib.escapeShellArgs (lib.attrNames config.services.sanoid.datasets)}; do
                  if ! ${zfs} snapshot "$dataset@preswitch_$stamp"; then
                    echo "warning: zfs snapshot $dataset@preswitch_$stamp failed" >&2
                    continue
                  fi
                  if ! old=$(${zfs} list -H -t snapshot -o name -s creation -d 1 "$dataset" \
                    | ${pkgs.gnugrep}/bin/grep -F "$dataset@preswitch_" \
                    | ${pkgs.coreutils}/bin/head -n -${toString keep}); then
                    echo "warning: listing preswitch snapshots of $dataset failed" >&2
                    continue
                  fi
                  for snapshot in $old; do
                    if ! ${zfs} destroy "$snapshot"; then
                      echo "warning: zfs destroy $snapshot failed" >&2
                    fi
                  done
                done
                ;;
            esac
          '';
    };
}
