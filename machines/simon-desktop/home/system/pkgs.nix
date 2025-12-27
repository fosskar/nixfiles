{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # custom packages from flake
    #inputs.self.packages.${pkgs.system}.voquill
    # desktop apps
    webcord-vencord
    signal-desktop
    #protonvpn-gui
    #protonvpn-cli
    filen-desktop
    #bitwarden-desktop
    #(symlinkJoin {
    #  name = "element-desktop";
    #  paths = [ element-desktop ];
    #  buildInputs = [ makeWrapper ];
    #  postBuild = ''
    #    wrapProgram $out/bin/element-desktop \
    #      --add-flags "--password-store=gnome-libsecret"
    #  '';
    #})
    fluffychat

    # media
    spotify

    obsidian

    # audio
    #teamspeak3
    teamspeak6-client

    #keepassxc
    # gaming
    #gamescope
    #r2modman
    #lutris
    #wineWowPackages.stable
    #wineWowPackages.waylandFull
    #winetricks
    #protontricks
    #bottles
    #path-of-building
    #gfn-electron

    # needed for graphene installer
    #android-udev-rules
    #android-tools

    kubectl
    kubernetes-helm
    talosctl
    clusterctl

    # drone
    # Override betaflight-configurator to use an older nwjs version
    # commented out due to qtwebengine-5.15.19 insecurity issues
    #(betaflight-configurator.override {
    #  nwjs = pkgs.nwjs.overrideAttrs rec {
    #    version = "0.84.0";
    #    src = pkgs.fetchurl {
    #      url = "https://dl.nwjs.io/v${version}/nwjs-v${version}-linux-x64.tar.gz";
    #      hash = "sha256-VIygMzCPTKzLr47bG1DYy/zj0OxsjGcms0G1BkI/TEI=";
    #    };
    #  };
    #})
    libatomic_ops

    lmstudio
  ];
}
