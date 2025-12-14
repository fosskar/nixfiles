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
  rollback =
    if cfg.rollbackType == "zfs" then
      zfs
    else if cfg.rollbackType == "btrfs" then
      btrfs
    else
      null;

  # check if /var/lib/private or /var/lib is persisted (needs permission fix)
  getDirPath = d: if builtins.isString d then d else d.directory or "";
  allDirs = cfg.directories;
  needsPrivateFix = builtins.any (
    d:
    let
      path = getDirPath d;
    in
    path == "/var/lib/private" || path == "/var/lib"
  ) allDirs;
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.nixfiles.impermanence = {
    enable = lib.mkEnableOption "impermanence with rollback support";

    rollbackType = lib.mkOption {
      type = lib.types.enum [
        "zfs"
        "btrfs"
        "none"
      ];
      default = "none";
      description = "filesystem type for rollback (zfs, btrfs, or none)";
    };

    zfs = {
      dataset = lib.mkOption {
        type = lib.types.str;
        default = "znixos/root";
        description = "zfs dataset to rollback";
      };
      snapshot = lib.mkOption {
        type = lib.types.str;
        default = "blank";
        description = "snapshot name to rollback to";
      };
      importService = lib.mkOption {
        type = lib.types.str;
        default = "zfs-import-znixos.service";
        description = "zfs import service to wait for";
      };
    };

    btrfs = {
      rootDeviceLabel = lib.mkOption {
        type = lib.types.str;
        default = "root";
        description = "label of the btrfs root device (used as /dev/disk/by-label/<label>)";
      };
      rootSubvolume = lib.mkOption {
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
    # rollback service (from zfs.nix or btrfs.nix)
    boot.initrd.systemd.services = lib.mkIf (rollback != null) rollback.service;

    # common persistence config
    environment.persistence.${cfg.persistPath} = {
      hideMounts = lib.mkDefault true;
      directories = [
        "/var/lib/nixos"
        "/var/lib/systemd"
      ]
      ++ lib.optional cfg.manageSopsMount "/var/lib/sops-nix"
      ++ cfg.directories;
      files = [
        "/etc/machine-id"
      ]
      ++ cfg.files;
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
