{ lib, pkgs, ... }:
{
  environment = {
    defaultPackages = lib.mkForce [ ]; # no extra default packages are installed
    systemPackages = with pkgs; [
      curl
      dnsutils
      gitMinimal
      jq
      tcpdump
      nmap
      ouch # archiver
      wget
      yq-go
    ];
  };
}
