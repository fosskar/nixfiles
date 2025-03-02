{ pkgs, ... }:
{
  environment = {
    homeBinInPath = true;
    systemPackages = with pkgs; [
      toybox
      usbutils
      libarchive
      colmena
    ];
  };
}
