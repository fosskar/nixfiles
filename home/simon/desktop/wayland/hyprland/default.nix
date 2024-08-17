{ inputs, pkgs, ... }:
{
  imports = [
    ./binds.nix
    ./hyprmode.nix
    ./settings.nix
    ./rules.nix
    ./hyprlock.nix
    ./hypridle.nix
    ../ags/aylur-style.nix
    #../ags/hyprpanel.nix
    ./shortcuts_info.nix
    #./plugins.nix
  ];

  home.packages = with pkgs; [
    #xwaylandvideobridge #for screensharing xwayland application
    hyprshot # screenshot
    wl-clipboard # wayland clipboard
    hyprpicker # color picker
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default;
    xwayland.enable = true; # true is default, but i set it anyways
    systemd = {
      enable = true;
      variables = [ "--all" ];
      extraCommands = [
        "systemctl --user stop graphical-session.target"
        "systemctl --user start hyprland-session.target"
      ];
    };
  };
}
