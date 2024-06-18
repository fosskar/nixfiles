{ pkgs, ... }:
{
  imports = [
    ./config.nix
    ./i3status.nix
    ../rofi.nix
  ];
  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
    };
  };

  home.packages = with pkgs; [ i3lock ];
}
