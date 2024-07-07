{ config, pkgs, ... }:
let
  shortcut_info = pkgs.writeShellScriptBin "shortcut_info" ''
    yad --list --window-type=dialog --grid-lines=both --escape-ok --search-column=3 --buttons-layout=center --button="yad-ok:0" --title="Shortcuts" \
        --column="     Software                    " --column="Shortcut                    " --column="Action" \
        "Hyprland"  "Alt + Space"                     "Open application launcher" \
        "Hyprland"  "SUPER + Tab"                     "Open overview" \
        "Hyprland"  "Print"                           "Take a screenshot of a region" \
        "Hyprland"  "Ctrl + Print"                    "Take screenshot of current monitor" \
        "Hyprland"  "SUPER + Print"                   "Take Screenshot of a window" \
        "Hyprland"  "SUPER + W"                       "Open Firefox" \
        "Hyprland"  "SUPER + T"                       "Open Kitty" \
        "Hyprland"  "SUPER + E"                       "Open Yazi" \
        "Hyprland"  "Alt + Tab"                       "Focus current or last window" \
        "Hyprland"  "SUPER + G"                       "Toogle group" \
        "Hyprland"  "SUPER + Shift + E"               "Exit Hyprland" \
        "Hyprland"  "SUPER + Shift + Q"               "Close active Window" \
        "Hyprland"  "SUPER + V"                       "Switch a window between tiling and floating" \
        "Hyprland"  "SUPER + F"                       "Fullscreen" \
        "Hyprland"  "SUPER + O"                       "Fake fullscreen" \
        "Hyprland"  "SUPER + J"                       "Toggle split" \
        "Hyprland"  "SUPER + P"                       "Pseudo" \
        "Hyprland"  "SUPER + C"                       "Open VSCodium" \
        "Hyprland"  "SUPER + Z"                       "Open Zed Editor" \
        "Hyprland"  "SUPER + D"                       "Open Discord" \
        "Hyprland"  "SUPER + L"                       "Execute hyprlock" \
        "Hyprland"  "SUPER + H"                       "Shortcut cheatsheet" \
        "Hyprland"  "SUPER + M"                       "Move window to special workspace" \
        "Hyprland"  "SUPER + Next"                    "Toggle hypr-gamemode" \
        "Hyprland"  "SUPER + LeftArrow"               "Switch workspace" \
        "Hyprland"  "SUPER + RightArrow"              "Switch workspace" \
        "Hyprland"  "SUPER + UpArrow"                 "Switch window focus" \
        "Hyprland"  "SUPER + DownArror"               "Switch window focus" \
        "Kitty"     "Ctrl + Shift + T"                "New tab" \
        "Kitty"     "Ctrl + Shift + Enter"            "New window" \
        "Kitty"     "Ctrl + Shift + LeftArrow"        "Switch tab" \
        "Kitty"     "Ctrl + Shift + RightArrow"       "Switch tab" \
        "Kitty"     "Ctrl + Shift + RightArrow"       "Switch tab" \
        "Kitty"     "Ctrl + Shift + Q"                "Close tab" \
        "Kitty"     "Ctrl + Shift + C"                "Copy to clipboard" \
        "Kitty"     "Ctrl + Shift + V"                "Paste from clipboard" \
        "Kitty"     "Ctrl + Shift + S"                "Paste from selection" \
        "Kitty"     "Ctrl + Shift + ScrollUp"         "Scroll line up" \
        "Kitty"     "Ctrl + Shift + ScrollDown"       "Scroll line down" \
        "Kitty"     "Ctrl + Shift + K"                "Scroll line up" \
        "Kitty"     "Ctrl + Shift + J"                "Scroll line down" \
        "Kitty"     "Ctrl + Shift + G"                "Show last command output" \
        "Kitty"     "Ctrl + Shift + W"                "Close window" \
        "Kitty"     "Ctrl + Shift + F"                "Move window forward" \
        "Kitty"     "Ctrl + Shift + B"                "Move window backward" \
        "Kitty"     "Ctrl + Shift + [number]"         "Switch to window [number]" \
        "Kitty"     "Ctrl + Shift + L"                "Switch to next layout" \
        "Kitty"     "Ctrl + Shift + Z"                "Copy to clipboard" \
        "Kitty"     "Ctrl + Shift + Esc"              "Open kitty command shell" \
        "Kitty"     "Ctrl + Shift + Del"              "Reset terminal" \
        "VSCodium"  "Ctrl + Shift + P"                "Command palette" \
        "VSCodium"  "Ctrl + Shift + F"                "Search files" \
        "VSCodium"  "Ctrl + Shift + Left/RightArrow"  "Select text word by word" \
        "VSCodium"  "Alt + Up/DownArrow"              "Move line up/down" \
        "VSCodium"  "Ctrl + Alt + Up/DownArrow"        "Multiple cursors" \
        "VSCodium"  "Alt + LeftClick"                 "Place multiple cursors" \
        "VSCodium"  "Ctrl + Shift + K"                "Delete a line" \
        "VSCodium"  "Ctrl + K Ctrl + C"               "Comment lines" \
        "VSCodium"  "Alt + Enter"                     "Select all results of a find operation" \
        "VSCodium"  "Ctrl + B"                        "Toogle sidebar" \
        "VSCodium"  "Ctrl + L"                        "Select current line" \
        "VSCodium"  "Ctrl + Shift + V"                "Open markdown preview" \
  '';
in
{
  home.file."${config.xdg.configHome}/shortcut_info.sh" = {
    text = ''
      ${shortcut_info}/bin/shortcut_info
    '';
    executable = true;
  };

  home.packages = [
    pkgs.zenity
    pkgs.yad
  ];

}
