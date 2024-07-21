{ pkgs, ... }:
{
  networking = {
    firewall = {
      enable = true;
    };
    nftables = {
      enable = true;
    };
  };
}
