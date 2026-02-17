{ lib, pkgs, ... }:
{
  environment = {
    defaultPackages = lib.mkForce [ ]; # no extra default packages are installed
    systemPackages = with pkgs; [
      coreutils
      curl
      dnsutils
      fd
      findutils
      lsof
      gitMinimal
      jq
      tcpdump
      nmap
      wget
      unzip
      ripgrep
      pciutils
    ];
  };
}
