{
  config,
  pkgs,
  ...
}:
let
  hypr_gamemode = pkgs.writeShellScriptBin "hypr-gamemode" ''
    HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
    if [ "$HYPRGAMEMODE" = 1 ] ; then
      hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword animation borderangle,0; \
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:xray 1;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0;\
        keyword decoration:active_opacity 1 ;\
        keyword decoration:inactive_opacity 1 ;\
        keyword decoration:fullscreen_opacity 1 ;\
        keyword monitor "DP-1,2560x1440@164.9,0x0,1" 2> /dev/null"
      powerprofilesctl set performance
      echo cache | sudo tee /sys/bus/platform/drivers/amd_x3d_vcache/AMDI0101:00/amd_x3d_mode
      exit
    fi
    hyprctl reload
    powerprofilesctl set balanced
  '';
in
{
  # when activated this sets display and performance settings for gaming
  home.file."${config.xdg.configHome}/hypr/hypr-gamemode.sh" = {
    text = ''
      ${hypr_gamemode}/bin/hypr-gamemode
    '';
    executable = true;
  };
}
