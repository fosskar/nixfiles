{ pkgs, ... }:
{
  environment = {
    homeBinInPath = true;
    systemPackages = with pkgs; [
      wget
      dnsutils
      usbutils
      libarchive
      trash-cli

      zip
      unzip
      unrar
    ];
  };
}
