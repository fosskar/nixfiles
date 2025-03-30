{ pkgs, ... }:
{
  home.packages = with pkgs; [

    # desktop apps
    webcord-vencord
    #(lowPrio proton-pass) # FIXME package collision between proton-mail and proton-pass app.asar
    protonvpn-gui
    protonvpn-cli
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
  ];
}
