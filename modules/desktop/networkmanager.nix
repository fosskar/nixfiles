{ lib, config, ... }:
{
  # add wheel users to networkmanager group
  users.groups.networkmanager.members = config.users.groups.wheel.members;

  networking.networkmanager = {
    enable = lib.mkDefault true;
    # use systemd-resolved for DNS (enabled in base/network.nix)
    dns = lib.mkDefault "systemd-resolved";
    # wifi privacy/security defaults (harmless if no wifi hardware)
    wifi = {
      backend = lib.mkDefault "iwd";
      macAddress = lib.mkDefault "random";
      powersave = lib.mkDefault true;
      scanRandMacAddress = lib.mkDefault true;
    };
  };
}
