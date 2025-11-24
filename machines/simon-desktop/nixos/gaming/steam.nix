{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true;
    remotePlay.openFirewall = true;
    gamescopeSession.enable = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    package = pkgs.steam.override {
      extraEnv = {
        PROTON_ENABLE_WAYLAND = 1;
        PROTON_USE_NTSYNC = 1;
      };
      #  extraPkgs =
      #    pkgs: with pkgs; [
      #      keyutils
      #      libkrb5
      #      libpng
      #      libpulseaudio
      #      libvorbis
      #      stdenv.cc.cc.lib
      #      xorg.libXcursor
      #      xorg.libXi
      #      xorg.libXinerama
      #      xorg.libXScrnSaver
      #    ];
    };
  };
}
