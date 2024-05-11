{pkgs, ...}: {
  imports = [
    ./config.nix
    #../polybar.nix
  ];
  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
    };
  };
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    rofi
    i3blocks
    i3lock
    xautolock
    i3status
  ];
}
