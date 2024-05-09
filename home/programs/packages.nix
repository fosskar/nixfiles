{pkgs, ...}: {
  home.packages = with pkgs; [
    webcord-vencord
    spotify

    ## gaming
    goverlay
    teamspeak_client
    #lutris
    ## WINE
    #wineWowPackages.stable
    wineWowPackages.waylandFull
    winetricks
    #teamspeak5_client
    #bottles
    path-of-building
    ## Mods
    #r2modman
  ];
}
