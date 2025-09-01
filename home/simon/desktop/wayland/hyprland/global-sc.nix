{
  lib,
  config,
  pkgs,
  ...
}:
let
  electron-sc = pkgs.writeShellScriptBin "electron-sc" ''
    hyprctl activewindow | grep "$2: $3"
    if [[ $? -eq 0 ]]; then
        hyprctl dispatch sendshortcut $1, $2:$3
    else
        hyprctl --batch "dispatch focuswindow $2:$3; dispatch sendshortcut $1, $2:$3; dispatch focuscurrentorlast"
    fi
  '';
in
{

  # when activated this sets display and performance settings for gaming
  home.file."${config.xdg.configHome}/hypr/electron-sc.sh" = {
    text = ''
      ${electron-sc}/bin/electron-sc
    '';
    executable = true;
  };
}
