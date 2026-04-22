{
  self,
  lib,
  mylib,
  inputs,
  ...
}:
{
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    self.modules.nixos.borgbackup
    self.modules.nixos.crowdsec
    self.modules.nixos.btrfs
    self.modules.nixos.tuned
    self.modules.nixos.preservation
    self.modules.nixos.traefik
  ]
  ++ (mylib.scanPaths ./. { });

  # srvos.hardware-hetzner-cloud sets: qemuGuest, grub /dev/sda, networkd
  # srvos.server sets: emergency mode suppression

  nixpkgs.hostPlatform = "x86_64-linux";

  nixfiles = {
    preservation = {
      rollback = {
        type = "btrfs";
        deviceLabel = "root";
      };
      directories = [
        "/var/log"
        "/var/lib/private"
      ];
    };

    borgbackup = {
      useSnapshots = true;
      snapshotType = "btrfs";
    };

    tuned.profile = "virtual-guest";

    crowdsec = {
      traefik.enable = true;
      netbirdProxy.enable = true;
      whitelistClanMesh = true;
    };
    traefik.geoblock.enable = true;
  };

  clan.core = {
    settings.machine-id.enable = true;
  };

  services.cloud-init = {
    settings = {
      preserve_hostname = true;
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
      systemd-boot.enable = false;
      grub.enable = true;
    };
  };
}
