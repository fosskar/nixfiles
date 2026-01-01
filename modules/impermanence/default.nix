{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.nixfiles.impermanence;
  zfs = import ./zfs.nix { inherit cfg; };
  btrfs = import ./btrfs.nix { inherit cfg; };
  bcachefs = import ./bcachefs.nix { inherit cfg; };
  rollbackService =
    if cfg.rollback.type == "zfs" then
      zfs
    else if cfg.rollback.type == "btrfs" then
      btrfs
    else if cfg.rollback.type == "bcachefs" then
      bcachefs
    else
      null;

  # check if /var/lib/private or /var/lib is persisted (needs permission fix)
  getDirPath = d: if builtins.isString d then d else d.directory or "";
  allDirs = cfg.directories;
  needsPrivateFix = builtins.any (
    d:
    let
      dirPath = getDirPath d;
    in
    dirPath == "/var/lib/private" || dirPath == "/var/lib"
  ) allDirs;
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.nixfiles.impermanence = {
    enable = lib.mkEnableOption "impermanence with rollback support";

    rollback = {
      type = lib.mkOption {
        type = lib.types.enum [
          "zfs"
          "btrfs"
          "bcachefs"
          "none"
        ];
        default = "none";
        description = "filesystem type for rollback (zfs, btrfs, bcachefs, or none)";
      };

      # zfs options (required when type = "zfs")
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

      # btrfs options (required when type = "btrfs")
      deviceLabel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "label of the btrfs root device (required for btrfs)";
      };

      # bcachefs options (required when type = "bcachefs")
      partLabel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "GPT partition label of bcachefs device (required for bcachefs)";
      };

      # shared options for btrfs and bcachefs
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
      description = "whether to manage /var/lib/sops-nix as a bind mount (disable if managed elsewhere, e.g. disko)";
    };

    directories = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str (lib.types.attrsOf lib.types.anything));
      default = [ ];
      description = "additional directories to persist";
    };

    files = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "additional files to persist";
    };
  };

  config = lib.mkIf cfg.enable {
    # assertions for required rollback options
    assertions = [
      {
        assertion = cfg.rollback.type != "zfs" || cfg.rollback.dataset != null;
        message = "nixfiles.impermanence.rollback.dataset must be set when type is 'zfs'";
      }
      {
        assertion = cfg.rollback.type != "zfs" || cfg.rollback.poolImportService != null;
        message = "nixfiles.impermanence.rollback.poolImportService must be set when type is 'zfs'";
      }
      {
        assertion = cfg.rollback.type != "btrfs" || cfg.rollback.deviceLabel != null;
        message = "nixfiles.impermanence.rollback.deviceLabel must be set when type is 'btrfs'";
      }
      {
        assertion = cfg.rollback.type != "bcachefs" || cfg.rollback.partLabel != null;
        message = "nixfiles.impermanence.rollback.partLabel must be set when type is 'bcachefs'";
      }
    ];

    # rollback service (from zfs.nix, btrfs.nix, or bcachefs.nix)
    boot.initrd.systemd.services = lib.mkIf (rollbackService != null) rollbackService.service;

    # common persistence config
    environment.persistence.${cfg.persistPath} = {
      hideMounts = lib.mkDefault true;
      directories = [
        "/var/lib/nixos"
        "/var/lib/systemd"
      ]
      ++ lib.optional cfg.manageSopsMount "/var/lib/sops-nix"
      ++ cfg.directories;
      inherit (cfg) files;
    };

    # early mounts required for bind mounts and sops secrets
    fileSystems = {
      "/nix".neededForBoot = true;
      ${cfg.persistPath}.neededForBoot = true;
    }
    // lib.optionalAttrs cfg.manageSopsMount {
      "/var/lib/sops-nix".neededForBoot = true;
    };

    # fix /var/lib/private permissions for DynamicUser services
    # only needed when /var/lib or /var/lib/private is persisted
    system.activationScripts."var-lib-private-permissions" = lib.mkIf needsPrivateFix {
      deps = [ "specialfs" ];
      text = ''
        mkdir -p ${cfg.persistPath}/var/lib/private
        chmod 0700 ${cfg.persistPath}/var/lib/private
      '';
    };
    system.activationScripts."createPersistentStorageDirs".deps =
      lib.optional needsPrivateFix "var-lib-private-permissions"
      ++ [
        "users"
        "groups"
      ];
  };
}
