{ pkgs, ... }:
{
  networking = {
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
    };
    nftables = {
      enable = true;
    };
  };
}
