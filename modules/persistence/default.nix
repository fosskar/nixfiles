# persistence module using preservation
{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.persistence;

  # find bcachefs partition from disko config
  findBcachefsPartition = lib.pipe (config.disko.devices.disk or { }) [
    (lib.mapAttrsToList (
      diskName: disk:
      lib.mapAttrsToList (partName: part: {
        inherit diskName partName;
        type = part.content.type or "";
      }) (disk.content.partitions or { })
    ))
    lib.flatten
    (lib.findFirst (p: p.type == "bcachefs") null)
  ];

  # auto-derive partLabel from disko if available
  derivedPartLabel =
    if findBcachefsPartition != null then
      "disk-${findBcachefsPartition.diskName}-${findBcachefsPartition.partName}"
    else
      null;

  # use explicit partLabel if set, otherwise derive from disko
  effectivePartLabel =
    if cfg.rollback.partLabel != null then cfg.rollback.partLabel else derivedPartLabel;

  # pass effective partLabel to rollback modules
  effectiveCfg = cfg // {
    rollback = cfg.rollback // {
      partLabel = effectivePartLabel;
    };
  };

  # rollback services
  zfs = import ./zfs.nix { cfg = effectiveCfg; };
  btrfs = import ./btrfs.nix { cfg = effectiveCfg; };
  bcachefs = import ./bcachefs.nix { cfg = effectiveCfg; };
  rollbackService =
    if cfg.rollback.type == "zfs" then
      zfs
    else if cfg.rollback.type == "btrfs" then
      btrfs
    else if cfg.rollback.type == "bcachefs" then
      bcachefs
    else
      null;

  # extract directory path from string or attrset
  getDirPath = d: if builtins.isString d then d else d.directory or "";

  # all directories that need to exist on /persist during fresh install
  allPersistDirs = [
    "/var/lib/nixos"
    "/var/lib/systemd"
    "/var/log"
  ]
  ++ lib.optional cfg.manageSopsMount "/var/lib/sops-nix"
  ++ map getDirPath cfg.directories;

  # parent dirs for persisted files
  getFilePath = f: if builtins.isString f then f else f.file or "";
  fileParentDirs = map (f: builtins.dirOf (getFilePath f)) cfg.files;

  # all unique dirs to create
  installDirs = lib.unique (lib.sort (a: b: a < b) (allPersistDirs ++ fileParentDirs));

  mountPoint = config.disko.rootMountPoint or "/mnt";
in
{
  imports = [ ./preservation.nix ];

  options.nixfiles.persistence = {
    enable = lib.mkEnableOption "persistence with rollback support";

    rollback = {
      type = lib.mkOption {
        type = lib.types.enum [
          "zfs"
          "btrfs"
          "bcachefs"
          "none"
        ];
        default = "none";
        description = "filesystem type for rollback";
      };

      # zfs options
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

      # btrfs options
      deviceLabel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "label of the btrfs root device (required for btrfs)";
      };

      # bcachefs options
      partLabel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "GPT partition label of bcachefs device. Auto-derived from disko if not set.";
      };

      # shared options
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

    persistPath = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "path to persistent storage";
    };

    manageSopsMount = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "whether to manage /var/lib/sops-nix as a bind mount";
    };

    directories = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str (lib.types.attrsOf lib.types.anything));
      default = [ ];
      description = "directories to persist";
    };

    files = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str (lib.types.attrsOf lib.types.anything));
      default = [ ];
      description = "files to persist";
    };

    diskoPostMountHook = lib.mkOption {
      type = lib.types.lines;
      readOnly = true;
      description = "shell commands for disko postMountHook to pre-create persistent dirs during fresh install";
    };
  };

  config = lib.mkIf cfg.enable {
    # assertions for required rollback options
    assertions = [
      {
        assertion = cfg.rollback.type != "zfs" || cfg.rollback.dataset != null;
        message = "nixfiles.persistence.rollback.dataset must be set when type is 'zfs'";
      }
      {
        assertion = cfg.rollback.type != "zfs" || cfg.rollback.poolImportService != null;
        message = "nixfiles.persistence.rollback.poolImportService must be set when type is 'zfs'";
      }
      {
        assertion = cfg.rollback.type != "btrfs" || cfg.rollback.deviceLabel != null;
        message = "nixfiles.persistence.rollback.deviceLabel must be set when type is 'btrfs'";
      }
      {
        assertion = cfg.rollback.type != "bcachefs" || effectivePartLabel != null;
        message = "nixfiles.persistence.rollback.partLabel must be set (or disko must have a bcachefs partition)";
      }
    ];

    # rollback service (shared by both backends)
    boot.initrd.systemd.services = lib.mkIf (rollbackService != null) rollbackService.service;

    # early mounts
    fileSystems = {
      ${cfg.persistPath}.neededForBoot = true;
    };

    # auto-generated commands to pre-create persistent dirs during disko install
    nixfiles.persistence.diskoPostMountHook = lib.concatStringsSep "\n" (
      [ "# pre-create persistent directories for fresh install" ]
      ++ map (
        dir:
        let
          needsChmod = dir == "/var/lib/private";
          mkdirCmd = "mkdir -p ${mountPoint}${cfg.persistPath}${dir}";
          chmodCmd = lib.optionalString needsChmod " && chmod 0700 ${mountPoint}${cfg.persistPath}${dir}";
        in
        mkdirCmd + chmodCmd
      ) installDirs
    );
  };
}
