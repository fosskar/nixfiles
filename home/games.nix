{pkgs, ...}: {
  home.packages = with pkgs; [
    goverlay
    teamspeak_client
    protonup-qt
    lutris
    wineWowPackages.stable
    #wineWowPackages.waylandFull
    winetricks
    teamspeak5_client
    #bottles
    path-of-building
    #formods
    r2modman
  ];

  programs.mangohud = {
    enable = true;
    enableSessionWide = false;
  };
}
