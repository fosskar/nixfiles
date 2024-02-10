{
  inputs,
  lib,
  pkgs,
  hyprland,
  ...
}: {
  imports = [
    ./config.nix
    ../swayidle.nix
    ../swaylock.nix
    #./plugins.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    systemd.enable = true;
  };

  fonts.fontconfig.enable = true;

  systemd.user.sessionVariables = {
    "NIXOS_OZONE_WL" = "1";
    "MOZ_ENABLE_WAYLAND" = "1";
    "MOZ_WEBRENDER" = "1";
  };
  home.file.".config/wayland-sessions/hyprland.desktop".text = ''
    [Desktop Entry]
    Name=Hyprland
    Exec=Hyprland
    Type=Application
  '';
}
