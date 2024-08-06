{ pkgs, ... }:
{
  home.packages = with pkgs; [

    # desktop apps
    webcord-vencord
    protonmail-desktop
    (lowPrio proton-pass) # FIXME package collision between proton-mail and proton-pass app.asar
    bitwarden-desktop

    # media
    spotify

    # audio
    teamspeak_client
    teamspeak5_client

    # gaming
    #r2modman
    #lutris
    #wineWowPackages.stable
    #wineWowPackages.waylandFull
    #winetricks
    #bottles
    #path-of-building

    # archives
    zip
    unzip
    unrar
  ];
}
