{
  inputs,
  lib,
  pkgs,
  hyprland,
  ...
}: {
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./config.nix
    ./hyprlock.nix
    ./hypridle.nix
    #../swayidle.nix
    #../swaylock.nix
    #./plugins.nix
  ];

  home = {
    packages = with pkgs; [
      xwaylandvideobridge
      hyprshot
      wl-clipboard
      hyprpicker
      grim
      slurp
      udiskie
    ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    systemd = {
      enable = true;
    };
  };

  fonts.fontconfig.enable = true;

  home.file.".config/wayland-sessions/hyprland.desktop".text = ''
    [Desktop Entry]
    Name=Hyprland
    Exec=Hyprland
    Type=Application
  '';
}
