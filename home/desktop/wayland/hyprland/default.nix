{
  inputs,
  pkgs,
  hyprland,
  ...
}: {
  imports = [
    ./config.nix
    ./hyprlock.nix
    ./hypridle.nix
    ../ags
    #./plugins.nix
    #../swayidle.nix
    #../swaylock.nix
    #./waybar"
    #./wofi.nix"
    #./wlogout"
    #./dunst.nix"
  ];

  home = {
    packages = with pkgs; [
      xwaylandvideobridge
      hyprshot
      wl-clipboard
      hyprpicker
      grim
      slurp
    ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
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
