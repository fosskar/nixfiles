{ config, ... }:
let
  flakeMods = config.flake.modules.nixos;
in
{
  flake.modules.nixos.preservation =
    {
      config,
      lib,
      inputs,
      ...
    }:
    let
      cfg = config.preservation;

      toPreservationDir =
        d:
        let
          base = if builtins.isString d then { directory = d; } else d;
          withMode =
            if base.directory == "/var/lib/private" then base // { mode = base.mode or "0700"; } else base;
        in
        { how = "bindmount"; } // withMode;

      persistPath = "/persist";

      preserveCfg = config.preservation.preserveAt.${persistPath};

      getDirPath = d: if builtins.isString d then d else d.directory or "";
      getFilePath = f: if builtins.isString f then f else f.file or "";

      allPersistDirs = map getDirPath preserveCfg.directories;
      fileParentDirs = map (f: dirOf (getFilePath f)) preserveCfg.files;

      installDirs = lib.unique (lib.sort (a: b: a < b) (allPersistDirs ++ fileParentDirs));

      mountPoint = config.disko.rootMountPoint or "/mnt";
    in
    {
      imports = [
        inputs.preservation.nixosModules.preservation
        flakeMods.preservationRollbackBtrfs
        flakeMods.preservationRollbackZfs
        flakeMods.preservationRollbackBcachefs
      ];

      options.preservation = {
        rollback = {
          type = lib.mkOption {
            type = lib.types.enum [
              "zfs"
              "btrfs"
              "bcachefs"
              "none"
            ];
            default = "none";
            description = ''
              filesystem type for rollback. auto-derived from the
              fsType of `/` (btrfs/zfs/bcachefs); set explicitly to
              "none" to disable rollback on a supported filesystem.
            '';
          };

          dataset = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "zfs dataset to rollback (required for zfs)";
          };
          snapshot = lib.mkOption {
            type = lib.types.str;
            default = "blank";
            description = "zfs snapshot name to rollback to";
          };
          poolImportService = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "zfs import service to wait for (required for zfs)";
          };

          deviceLabel = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "label of the btrfs root device (required for btrfs)";
          };

          partLabel = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "GPT partition label of bcachefs device. Auto-derived from disko if not set.";
          };

          subvolume = lib.mkOption {
            type = lib.types.str;
            default = "@root";
            description = "name of root subvolume";
          };
          retentionDays = lib.mkOption {
            type = lib.types.int;
            default = 30;
            description = "days to keep old root backups";
          };
        };
      };

      config = {
        preservation.rollback.type =
          let
            rootFsType = config.fileSystems."/".fsType or null;
          in
          lib.mkDefault (
            if rootFsType == "btrfs" || rootFsType == "zfs" || rootFsType == "bcachefs" then
              rootFsType
            else
              "none"
          );

        assertions = [
          {
            assertion = cfg.rollback.type != "zfs" || cfg.rollback.dataset != null;
            message = "preservation.rollback.dataset must be set when type is 'zfs'";
          }
          {
            assertion = cfg.rollback.type != "zfs" || cfg.rollback.poolImportService != null;
            message = "preservation.rollback.poolImportService must be set when type is 'zfs'";
          }
          {
            assertion = cfg.rollback.type != "btrfs" || cfg.rollback.deviceLabel != null;
            message = "preservation.rollback.deviceLabel must be set when type is 'btrfs'";
          }
        ];

        fileSystems.${persistPath}.neededForBoot = true;

        _module.args.preservationDiskoPostMountHook = lib.concatStringsSep "\n" (
          [ "# pre-create persistent directories for fresh install" ]
          ++ map (
            dir:
            let
              needsChmod = dir == "/var/lib/private";
              mkdirCmd = "mkdir -p ${mountPoint}${persistPath}${dir}";
              chmodCmd = lib.optionalString needsChmod " && chmod 0700 ${mountPoint}${persistPath}${dir}";
            in
            mkdirCmd + chmodCmd
          ) installDirs
        );

        # point userborn at persistent storage so passwd/group/shadow survive
        # ephemeral root. userborn creates /etc symlinks automatically.
        services.userborn.passwordFilesLocation = lib.mkIf (config.services.userborn.enable or false
        ) "${persistPath}/etc";

        preservation = {
          enable = true;

          preserveAt.${persistPath} = {
            directories =
              map toPreservationDir [
                "/var/lib/nixos"
                "/var/lib/systemd"
                "/var/log"
              ]
              ++ lib.optional true {
                directory = "/var/lib/sops-nix";
                how = "bindmount";
                inInitrd = true;
              }
              ++ lib.optional true {
                directory = "/etc/secret-vars";
                how = "bindmount";
                inInitrd = true;
              };

            files = [
              {
                file = "/etc/machine-id";
                how = "symlink";
                inInitrd = true;
                createLinkTarget = true;
              }
            ];
          };
        };
      };
    };
}
