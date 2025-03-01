{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    toybox
    usbutils
    libarchive
    colmena
  ];
}
