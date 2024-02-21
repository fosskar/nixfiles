{
  pkgs,
  home-manager,
  ...
}: {
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
  home.file.".config/xsessions/i3.desktop".text = ''
    [Desktop Entry]
    Name=i3
    Exec=startx /home/simon/.xsession
    Type=XSession
  '';
}
