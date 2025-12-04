{ inputs, lib, ... }:
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  boot.initrd.systemd.services.btrfs-rollback = {
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

  environment.persistence."/persist" = {
    hideMounts = lib.mkDefault true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      {
        directory = "/var/lib/sops-nix";
        mode = "0755";
      }
      {
        directory = "/var/lib/pangolin";
        user = "pangolin";
        group = "fossorial";
        mode = "0755";
      }
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  fileSystems = {
    "/persist".neededForBoot = true;
    "/nix".neededForBoot = true;
    "/var/lib/sops-nix".neededForBoot = true;
  };
}
