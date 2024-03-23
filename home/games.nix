{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    goverlay
    teamspeak_client
    lutris
    ## WINE
    #wineWowPackages.stable
    wineWowPackages.waylandFull
    winetricks
    protonup-qt
    #teamspeak5_client
    #bottles
    path-of-building
    ## Mods
    #r2modman
    inputs.nix-gaming.packages.${pkgs.system}.star-citizen
  ];

  programs.mangohud = {
    enable = true;
    enableSessionWide = false;
  };
}
