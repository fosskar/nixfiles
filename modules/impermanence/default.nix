{
  lib,
  inputs,
  config,
  mylib,
  ...
}:
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ]
  ++ (mylib.scanPaths ./. { exclude = [ ]; });

  boot.initrd = {
    supportedFilesystems = [ "btrfs" ];
    systemd = {
      enable = true;
      services.btrfs-rollback = {
        description = "rollback btrfs root subvolume to a pristine state";
        wantedBy = [ "initrd.target" ];
        requires = [ "dev-disk-by\\x2dpartlabel-root.device" ];
        after = [ "dev-disk-by\\x2dpartlabel-root.device" ];
        before = [
          "-.mount"
          "sysroot.mount"
        ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
          mkdir -p /tmp
          MNTPOINT=$(mktemp -d)
          (
            mount -t btrfs -o subvol=/ /dev/disk/by-label/root "$MNTPOINT"
            trap 'umount "$MNTPOINT"' EXIT

            if [[ -e "$MNTPOINT/@root" ]]; then
              echo "backing up current root subvolume"
              mkdir -p "$MNTPOINT/old_roots"
              timestamp=$(date --date="@$(stat -c %Y "$MNTPOINT/@root")" "+%Y-%m-%d_%H:%M:%S")
              mv "$MNTPOINT/@root" "$MNTPOINT/old_roots/$timestamp"
            fi

            echo "cleaning old backups (>30 days)"
            find "$MNTPOINT/old_roots" -maxdepth 1 -mtime +30 -type d | while read -r old_root; do
              echo "deleting old backup: $old_root"
              btrfs subvolume delete "$old_root" || true
            done

            echo "creating fresh root subvolume"
            btrfs subvolume create "$MNTPOINT/@root"
          )
        '';
      };
    };
  };

  fileSystems = {
    "/persist".neededForBoot = true;
    "/nix".neededForBoot = true;
  };

  # point agenix to use the persisted ssh key directly
  #age.identityPaths = [
  #  "/persist/etc/ssh/ssh_host_ed25519_key"
  #];

  environment.persistence."/persist" = {
    hideMounts = lib.mkDefault true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
    ];
    files = [
      (lib.mkIf (!config.boot.isContainer) "/etc/machine-id")
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
}
