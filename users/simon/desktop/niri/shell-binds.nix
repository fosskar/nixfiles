{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (config.nixfiles.desktop) shell;
  isDms = shell == "dms";
  isNoctalia = shell == "noctalia";

  # DMS IPC helper
  dms-pkg = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
  dms-ipc = target: action: args: {
    spawn = [
      "qs"
      "ipc"
      "--any-display"
      "-p"
      "${dms-pkg}/share/quickshell/dms"
      "call"
      target
      action
    ]
    ++ args;
  };

  # Noctalia IPC helper
  noctalia-ipc = target: action: { spawn-sh = "noctalia-shell ipc call ${target} ${action}"; };

  # unified interface - returns action based on active shell
  shellAction =
    { dms, noctalia }:
    if isDms then
      dms
    else if isNoctalia then
      noctalia
    else
      {
        spawn = [ "true" ];
      }; # no-op for "none"
in
lib.mkIf (shell != "none") {
  programs.niri.settings.binds = {
    # shell widget toggles
    "Mod+Space" = {
      action = shellAction {
        dms = dms-ipc "spotlight" "toggle" [ ];
        noctalia = noctalia-ipc "launcher" "toggle";
      };
      hotkey-overlay.title = "Toggle Launcher";
    };

    "Mod+B" = {
      action = shellAction {
        dms = dms-ipc "clipboard" "toggle" [ ];
        noctalia = noctalia-ipc "launcher" "clipboard";
      };
      hotkey-overlay.title = "Toggle Clipboard";
    };

    "Mod+X" = {
      action = shellAction {
        dms = dms-ipc "powermenu" "toggle" [ ];
        noctalia = noctalia-ipc "sessionMenu" "toggle";
      };
      hotkey-overlay.title = "Toggle Power Menu";
    };

    "Mod+Shift+L" = {
      action = shellAction {
        dms = dms-ipc "lock" "lock" [ ];
        noctalia = noctalia-ipc "lockScreen" "lock";
      };
      hotkey-overlay.title = "Lock Screen";
    };

    "Mod+N" = {
      action = shellAction {
        dms = dms-ipc "notepad" "toggle" [ ];
        noctalia = noctalia-ipc "notifications" "toggleHistory";
      };
      hotkey-overlay.title = "Toggle Notifications";
    };

    "Mod+M" = {
      action = shellAction {
        dms = dms-ipc "processlist" "toggle" [ ];
        noctalia = noctalia-ipc "controlCenter" "toggle";
      };
      hotkey-overlay.title = "Toggle Control Center";
    };

    # audio controls
    "XF86AudioRaiseVolume" = {
      allow-when-locked = true;
      action = shellAction {
        dms = dms-ipc "audio" "increment" [ "5" ];
        noctalia = noctalia-ipc "volume" "increase";
      };
    };

    "XF86AudioLowerVolume" = {
      allow-when-locked = true;
      action = shellAction {
        dms = dms-ipc "audio" "decrement" [ "5" ];
        noctalia = noctalia-ipc "volume" "decrease";
      };
    };

    "XF86AudioMute" = {
      allow-when-locked = true;
      action = shellAction {
        dms = dms-ipc "audio" "mute" [ ];
        noctalia = noctalia-ipc "volume" "muteOutput";
      };
    };

    "XF86AudioMicMute" = {
      allow-when-locked = true;
      action = shellAction {
        dms = dms-ipc "audio" "micmute" [ ];
        noctalia = noctalia-ipc "volume" "muteInput";
      };
    };

    # brightness controls
    "XF86MonBrightnessUp" = {
      allow-when-locked = true;
      action = shellAction {
        dms = dms-ipc "brightness" "increment" [
          "10"
          "backlight:amdgpu_bl1"
        ];
        noctalia = noctalia-ipc "brightness" "increase";
      };
    };

    "XF86MonBrightnessDown" = {
      allow-when-locked = true;
      action = shellAction {
        dms = dms-ipc "brightness" "decrement" [
          "10"
          "backlight:amdgpu_bl1"
        ];
        noctalia = noctalia-ipc "brightness" "decrease";
      };
    };
  };
}
