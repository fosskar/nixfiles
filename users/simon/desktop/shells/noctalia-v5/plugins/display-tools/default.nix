{ pkgs, ... }:
let
  displayToolsLua =
    builtins.replaceStrings
      [
        "@niri@"
        "@jq@"
        "@wl_mirror@"
        "@wdisplays@"
        "@kanshictl@"
        "@pkill@"
        "@pgrep@"
        "@sh@"
      ]
      [
        "${pkgs.niri}/bin/niri"
        "${pkgs.jq}/bin/jq"
        "${pkgs.wl-mirror}/bin/wl-mirror"
        "${pkgs.wdisplays}/bin/wdisplays"
        "${pkgs.kanshi}/bin/kanshictl"
        "${pkgs.procps}/bin/pkill"
        "${pkgs.procps}/bin/pgrep"
        "${pkgs.bash}/bin/sh"
      ]
      (builtins.readFile ./display-tools.lua);
  displayToolsScript = pkgs.writeText "noctalia-display-tools.lua" displayToolsLua;
in
{
  programs.noctalia-v5.settings.widget.display-tools = {
    type = "scripted";
    script = toString displayToolsScript;
    hot_reload = false;
    left_click = "wdisplays";
    right_click = "mirror";
    middle_click = "extend-right";
  };
}
