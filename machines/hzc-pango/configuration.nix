{ mylib, inputs, ... }:
{
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    ../../modules/power
  ]
  ++ (mylib.scanPaths ./. { exclude = [ ]; });

  # srvos.hardware-hetzner-cloud sets: qemuGuest, grub /dev/sda, networkd
  # srvos.server sets: emergency mode suppression

  nixpkgs.hostPlatform = "x86_64-linux";

  nixfiles.power.tuned = {
    enable = true;
    profile = "virtual-guest";
  };

  clan.core.settings.machine-id.enable = true;

  services.cloud-init.settings.preserve_hostname = true;

  boot = {
    loader = {
      # override base profile defaults for hetzner cloud (legacy BIOS)
      systemd-boot.enable = false;
      grub.enable = true;
      # srvos sets grub.devices = ["/dev/sda"]
    };
    # btrfs support (disko handles actual fs config)
    supportedFilesystems = [ "btrfs" ];
    initrd.supportedFilesystems = [ "btrfs" ];
  };
}
