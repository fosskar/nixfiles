{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./binds.nix
    ./settings.nix
    ./rules.nix
    ../hyprlock.nix
    ../hypridle.nix
    ../ags
    #./plugins.nix
    #./waybar"
  ];

  home.packages = with pkgs; [
    xwaylandvideobridge #for screensharing xwayland application
    hyprshot
    wl-clipboard
    hyprpicker
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd = {
      enable = true;
      variables = ["--all"];
      extraCommands = [
        "systemctl --user stop graphical-session.target"
        "systemctl --user start hyprland-session.target"
      ];
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
