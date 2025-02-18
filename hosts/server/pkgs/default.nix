{ lib, pkgs, ... }:
{
  environment = {
    defaultPackages = lib.mkForce [ ]; # no extra default packages are installed
    systemPackages = with pkgs; [
      tcpdump
      neovim
      btop
      bat
      iproute2
      jq
      curl
      dig
      dnsutils
    ];
  };
}
