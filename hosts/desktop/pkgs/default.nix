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
      mesa-demos
      vulkan-tools
      jq
      yq-go
      nmap

      zip
      unzip
      unrar

      libreoffice

      quickemu

      apacheHttpd
    ];
  };
}
