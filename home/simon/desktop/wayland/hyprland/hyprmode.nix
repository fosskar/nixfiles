{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.module.desktop.wayland.hyprland.hyprlock;

  hypr_gamemode = pkgs.writeShellScriptBin "hypr-gamemode" ''
    HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')

    if [ "$HYPRGAMEMODE" = 1 ] ; then
      hyprctl keyword animations:enabled 0
      hyprctl keyword decoration:drop_shadow 0
      hyprctl keyword decoration:blur:enabled 0
      hyprctl keyword general:gaps_in 0
      hyprctl keyword general:gaps_out 0
      hyprctl keyword general:border_size 1
      hyprctl keyword decoration:rounding 0
      hyprctl keyword misc:vfr 0
      hyprctl keyword monitor "DP-1,2560x1440@165,0x0,1" 2> /dev/null
      powerprofilesctl set performance
      exit
    fi
    hyprctl keyword monitor "DP-1,3440x1440@165,0x0,1" 2> /dev/null
    hyprctl reload
    powerprofilesctl set balanced
  '';
in
{

  options = {
    module.desktop.wayland.hyprland.hyprmode.enable = mkEnableOption "Enables hyprmode";
  };

  config = mkIf cfg.enable {
    # when activated this sets display and performance settings for gaming
    home.file."${config.xdg.configHome}/hypr/hypr-gamemode.sh" = {
      text = ''
        ${hypr_gamemode}/bin/hypr-gamemode
      '';
      executable = true;
    };
  };
}
