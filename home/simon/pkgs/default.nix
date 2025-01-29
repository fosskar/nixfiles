{ pkgs, ... }:
{
  home.packages = with pkgs; [

    # desktop apps
    #webcord-vencord
    protonmail-desktop
    (lowPrio proton-pass) # FIXME package collision between proton-mail and proton-pass app.asar
    protonvpn-gui
    bitwarden-desktop
    #element-desktop-wayland

    # media
    spotify

    # audio
    teamspeak3
    teamspeak5_client

    # gaming
    #r2modman
    #lutris
    #wineWowPackages.stable
    #wineWowPackages.waylandFull
    #winetricks
    bottles
    path-of-building

    # archives
    zip
    unzip
    unrar

    # needed for graphene installer
    #android-udev-rules
    #android-tools

    kubectl
  ];
}
