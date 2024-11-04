{ pkgs, ... }:
{
  hardware.firmware = with pkgs; [ linux-firmware ];
  services.fwupd.enable = true;
}
