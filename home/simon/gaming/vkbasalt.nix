{ pkgs, ... }:
let

  xdg.configHome =
    let
      x = builtins.getEnv "XDG_CONFIG_HOME";
    in
    if x != "" then x else "${builtins.getEnv "HOME"}/.config";
in
{
  home.packages = [ pkgs.vkbasalt ];

  home.file."${xdg.configHome}/vkBasalt/vkBasalt.conf".text = ''
    effects = cas
    toggleKey = F5
    enableOnLaunch = True
    casSharpness = 0.5
  '';
}
