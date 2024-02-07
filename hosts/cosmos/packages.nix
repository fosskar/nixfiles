{
  pkgs,
  config,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [
    git
    neofetch
    neovim
    linuxPackages.cpupower
    btop
    bat
    curl
    alejandra
    corectrl
    dig
    lm_sensors
    # Hyprland
    waybar
    wlogout
    wl-clipboard
    hyprpicker
    grim
    slurp
    # i3
    rofi
    i3blocks
    i3lock
    xautolock
    i3status
    i3-gaps
  ];

  programs = {
    steam = {
      enable = true;
      package = pkgs.steam.override {
        extraEnv = {};
        extraLibraries = pkgs:
          with pkgs; [
            xorg.libXcursor
            xorg.libXi
            xorg.libXinerama
            xorg.libXScrnSaver
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib
            libkrb5
            keyutils
          ];
      };
    };
    #gamescope = {
    #  enable = true;
    #  capSysNice = true;
    #};
  };
}
