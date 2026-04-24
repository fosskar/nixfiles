{ lib, pkgs, ... }:
let
  noctalia =
    cmd:
    [
      "noctalia-shell"
      "ipc"
      "call"
    ]
    ++ (pkgs.lib.splitString " " cmd);

  shellBinds = {
    "Mod+Space" = {
      title = "Toggle Launcher";
      t = "launcher";
      a = "toggle";
    };
    "Mod+B" = {
      title = "Toggle Clipboard";
      t = "launcher";
      a = "clipboard";
    };
    "Mod+G" = {
      title = "Toggle Power Menu";
      t = "plugin:nostr-chat";
      a = "toggle";
    };
    "Mod+X" = {
      title = "Toggle Power Menu";
      t = "sessionMenu";
      a = "toggle";
    };
    "Mod+Shift+L" = {
      title = "Lock Screen";
      t = "lockScreen";
      a = "lock";
    };
    "Mod+N" = {
      title = "Toggle Notifications";
      t = "notifications";
      a = "toggleHistory";
    };
    "Mod+M" = {
      title = "Toggle Control Center";
      t = "controlCenter";
      a = "toggle";
    };
    "XF86AudioRaiseVolume" = {
      locked = true;
      t = "volume";
      a = "increase";
    };
    "XF86AudioLowerVolume" = {
      locked = true;
      t = "volume";
      a = "decrease";
    };
    "XF86AudioMute" = {
      locked = true;
      t = "volume";
      a = "muteOutput";
    };
    "XF86AudioMicMute" = {
      locked = true;
      t = "volume";
      a = "muteInput";
    };
    "XF86MonBrightnessUp" = {
      locked = true;
      t = "brightness";
      a = "increase";
    };
    "XF86MonBrightnessDown" = {
      locked = true;
      t = "brightness";
      a = "decrease";
    };
  };
in
{
  programs.niri.settings.binds = lib.mapAttrs (
    _: bind:
    {
      action.spawn = noctalia "${bind.t} ${bind.a}";
    }
    // lib.optionalAttrs (bind ? title) { hotkey-overlay.title = bind.title; }
    // lib.optionalAttrs (bind.locked or false) { allow-when-locked = true; }
  ) shellBinds;
}
