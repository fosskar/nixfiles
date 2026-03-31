{
  lib,
  mylib,
  inputs,
  ...
}:
{
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    ../../modules/borgbackup
    ../../modules/crowdsec
    ../../modules/filesystems/btrfs.nix
    ../../modules/power
    ../../modules/persistence
    ../../modules/traefik
  ]
  ++ (mylib.scanPaths ./. { });

  # srvos.hardware-hetzner-cloud sets: qemuGuest, grub /dev/sda, networkd
  # srvos.server sets: emergency mode suppression

  nixpkgs.hostPlatform = "x86_64-linux";

  nixfiles = {
    persistence = {
      enable = true;
      rollback = {
        type = "btrfs";
        deviceLabel = "root";
      };
      directories = [
        "/var/log"
        "/var/lib/private"
      ];
    };
    # backup
    borgbackup = {
      enable = true;
      useSnapshots = true;
      snapshotType = "btrfs";
    };

    power.tuned = {
      enable = true;
      profile = "virtual-guest";
    };

    crowdsec = {
      traefik.enable = true;
      whitelistClanMesh = true;
    };
    traefik.geoblock.enable = true;
  };

  clan.core = {
    settings.machine-id.enable = true;
    # Build gateway on a stronger host; this VPS can stay target-only.
    #networking.buildHost = "root@simon-desktop.s";
  };

  services.cloud-init = {
    settings = {
      preserve_hostname = true;
      # Force module list so cloud-init doesn't run users-groups on NixOS/userborn setup.
      cloud_init_modules = lib.mkForce [
        "migrator"
        "seed_random"
        "bootcmd"
        "write-files"
        "growpart"
        "resizefs"
        "resolv_conf"
        "ca-certs"
        "rsyslog"
      ];
    };
  };

  boot = {
    loader = {
      # override base profile defaults for hetzner cloud (legacy BIOS)
      systemd-boot.enable = false;
      grub.enable = true;
      # srvos sets grub.devices = ["/dev/sda"]
    };
  };
}
