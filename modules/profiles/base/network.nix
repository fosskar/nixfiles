{ lib, ... }:
{
  # srvos sets: useNetworkd, wait-online disables, stopIfChanged settings

  networking.dhcpcd.enable = lib.mkDefault false;

  services.resolved = {
    enable = lib.mkDefault true;
    # srvos.server sets llmnr, but desktop doesn't - keep for both
    settings.Resolve.LLMNR = lib.mkDefault "false";
  };
}
