{
  flake.modules.nixos.zfs =
    {
      config,
      lib,
      pkgs,
      utils,
      ...
    }:
    let
      datasets = config.nixfiles.zfs.datasets;
      poolOf = name: lib.head (lib.splitString "/" name);
      pools = lib.unique (map poolOf (lib.attrNames datasets));
      mounted = lib.filterAttrs (_: dataset: dataset.mountPoint != null) datasets;
      # pools holding filesystems needed for boot are imported in the initrd
      # and have no stage-2 zfs-import unit to order after
      rootPools = lib.unique (
        map (fs: poolOf fs.device) (
          lib.filter (fs: fs.fsType == "zfs" && utils.fsNeededForBoot fs) (lib.attrValues config.fileSystems)
        )
      );
    in
    {
      options.nixfiles.zfs.datasets = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                mountPoint = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = "/${name}";
                  description = ''
                    where the legacy-mountpoint dataset is mounted. null creates
                    the dataset with mountpoint=none and never mounts it.
                  '';
                };
                properties = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                  example = {
                    "com.sun:auto-snapshot" = "false";
                    recordsize = "1M";
                  };
                  description = "zfs properties set on creation and re-applied on every boot.";
                };
              };
            }
          )
        );
        default = { };
        description = ''
          zfs datasets on data pools, keyed by dataset name, created with
          mountpoint=legacy and mounted via fileSystems. a dataset is only created
          when its mount point is missing or empty; existing data has to be
          migrated by hand. datasets are never destroyed, and removed properties
          are not reset.
        '';
      };

      config = {
        assertions = map (pool: {
          assertion = !(lib.elem pool rootPools);
          message = "nixfiles.zfs.datasets: ${pool} is imported in the initrd; declare its datasets with disko instead";
        }) pools;

        fileSystems = lib.mapAttrs' (
          name: dataset:
          lib.nameValuePair dataset.mountPoint {
            device = name;
            fsType = "zfs";
            # nofail drops the ordering before local-fs.target; restore it so
            # systemd-tmpfiles-setup and services apply their ownership rules
            # to the mounted dataset, not to the empty mount point below it
            options = [
              "nofail"
              "x-systemd.before=local-fs.target"
            ];
          }
        ) mounted;

        systemd.services = lib.mkMerge [
          # the import unit lists every mount of its pool in Before=, so each
          # new dataset changes it. restarting it on switch stops all mounts of
          # the pool and every service on them; the pool stays imported, so
          # there is nothing to redo.
          (lib.genAttrs (map (pool: "zfs-import-${pool}") pools) (_: {
            restartIfChanged = false;
          }))

          (lib.mapAttrs' (
            name: dataset:
            let
              mountUnit = "${utils.escapeSystemdPath dataset.mountPoint}.mount";
              importUnit = "zfs-import-${poolOf name}.service";
              properties = lib.mapAttrsToList (key: value: "${key}=${value}") dataset.properties;
              isMounted = dataset.mountPoint != null;
            in
            lib.nameValuePair "zfs-dataset-${utils.escapeSystemdPath name}" {
              description = "create zfs dataset ${name}";
              requires = [ importUnit ];
              after = [ importUnit ];
              # wants, not requires: restarting this unit on a property change
              # must not stop the mount and every service requiring it. a missing
              # dataset still fails the mount.
              # multi-user.target lets switch start new units and apply new
              # properties while the mount is already active
              wantedBy = lib.optional isMounted mountUnit ++ [ "multi-user.target" ];
              before = lib.optional isMounted mountUnit;
              stopIfChanged = false;
              # mount units come before local-fs.target, which default service
              # dependencies would order after
              unitConfig = {
                DefaultDependencies = false;
              }
              // lib.optionalAttrs isMounted {
                RequiresMountsFor = [ (dirOf dataset.mountPoint) ];
              };
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              path = [
                config.boot.zfs.package
                pkgs.coreutils
                pkgs.gnugrep
              ];
              script = ''
                if zfs list -H -o name -t filesystem | grep -qFx ${lib.escapeShellArg name}; then
                  ${lib.optionalString (properties != [ ]) ''
                    zfs set ${lib.escapeShellArgs properties} ${lib.escapeShellArg name}
                  ''}
                  exit 0
                fi
              ''
              + lib.optionalString isMounted ''
                mountPoint=${lib.escapeShellArg dataset.mountPoint}
                # the new dataset would hide data written into the parent
                if [ -d "$mountPoint" ] && [ -n "$(ls -A "$mountPoint")" ]; then
                  echo "$mountPoint is not empty; migrate it into ${name} by hand" >&2
                  exit 1
                fi
              ''
              + ''
                zfs create -o mountpoint=${if isMounted then "legacy" else "none"} ${
                  lib.concatMapStringsSep " " (property: "-o ${lib.escapeShellArg property}") properties
                } ${lib.escapeShellArg name}
              '';
            }
          ) datasets)
        ];
      };
    };
}
