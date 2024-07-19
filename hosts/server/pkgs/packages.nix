{ lib, pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      git
      #neofetch
      neovim
      btop
      bat
      curl
      dig
      # hypervisor
      qemu
      k9s
    ];
    defaultPackages = lib.mkForce [ ]; # no extra default packages are installed
  };
}
