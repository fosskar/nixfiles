{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # desktop apps
    webcord-vencord
    #protonvpn-gui
    #protonvpn-cli
    filen-desktop
    #bitwarden-desktop
    #element-desktop-wayland

    # media
    spotify

    obsidian

    # audio
    teamspeak3
    teamspeak5_client

    # gaming
    #r2modman
    #lutris
    #wineWowPackages.stable
    #wineWowPackages.waylandFull
    #winetricks
    #bottles
    #path-of-building
    #gfn-electron

    # needed for graphene installer
    #android-udev-rules
    #android-tools

    kubectl
    kubernetes-helm

    # drone
    betaflight-configurator
  ];
}
