{ lib, pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      neovim
      btop
      bat
      curl
      dig
    ];
    defaultPackages = lib.mkForce [ ]; # no extra default packages are installed
  };
}
