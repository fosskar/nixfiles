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
    in
    {
      options.nixfiles.zfs.datasets = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                mountPoint = lib.mkOption {
                  type = lib.types.str;
                  default = "/${name}";
                  description = "where the legacy-mountpoint dataset is mounted.";
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
          zfs datasets, keyed by dataset name, created with mountpoint=legacy and
          mounted via fileSystems. a dataset is only created when its mount point
          is missing or empty; existing data has to be migrated by hand. datasets
          are never destroyed, and removed properties are not reset.
        '';
      };

      config = {
        fileSystems = lib.mapAttrs' (
          name: dataset:
          lib.nameValuePair dataset.mountPoint {
            device = name;
            fsType = "zfs";
            options = [ "nofail" ];
          }
        ) datasets;

        systemd.services = lib.mapAttrs' (
          name: dataset:
          let
            mountUnit = "${utils.escapeSystemdPath dataset.mountPoint}.mount";
            importUnit = "zfs-import-${lib.head (lib.splitString "/" name)}.service";
            properties = lib.mapAttrsToList (key: value: "${key}=${value}") dataset.properties;
          in
          lib.nameValuePair "zfs-dataset-${utils.escapeSystemdPath name}" {
            description = "create zfs dataset ${name}";
            requires = [ importUnit ];
            after = [ importUnit ];
            requiredBy = [ mountUnit ];
            before = [ mountUnit ];
            # mount units come before local-fs.target, which default service
            # dependencies would order after
            unitConfig = {
              DefaultDependencies = false;
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
              mountPoint=${lib.escapeShellArg dataset.mountPoint}
              # the new dataset would hide data written into the parent
              if [ -d "$mountPoint" ] && [ -n "$(ls -A "$mountPoint")" ]; then
                echo "$mountPoint is not empty; migrate it into ${name} by hand" >&2
                exit 1
              fi
              zfs create -o mountpoint=legacy ${
                lib.concatMapStringsSep " " (property: "-o ${lib.escapeShellArg property}") properties
              } ${lib.escapeShellArg name}
            '';
          }
        ) datasets;
      };
    };
}
