{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (config.nixfiles) quickshell;
  isDms = quickshell == "dms";
  isNoctalia = quickshell == "noctalia";

  dms-pkg = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # key → { title?, locked?, dms = { t, a, args? }, noctalia = { t, a } }
  shellBinds = {
    "Mod+Space" = {
      title = "Toggle Launcher";
      dms = {
        t = "spotlight";
        a = "toggle";
      };
      noctalia = {
        t = "launcher";
        a = "toggle";
      };
    };
    "Mod+B" = {
      title = "Toggle Clipboard";
      dms = {
        t = "clipboard";
        a = "toggle";
      };
      noctalia = {
        t = "launcher";
        a = "clipboard";
      };
    };
    "Mod+X" = {
      title = "Toggle Power Menu";
      dms = {
        t = "powermenu";
        a = "toggle";
      };
      noctalia = {
        t = "sessionMenu";
        a = "toggle";
      };
    };
    "Mod+Shift+L" = {
      title = "Lock Screen";
      dms = {
        t = "lock";
        a = "lock";
      };
      noctalia = {
        t = "lockScreen";
        a = "lock";
      };
    };
    "Mod+N" = {
      title = "Toggle Notifications";
      dms = {
        t = "notepad";
        a = "toggle";
      };
      noctalia = {
        t = "notifications";
        a = "toggleHistory";
      };
    };
    "Mod+M" = {
      title = "Toggle Control Center";
      dms = {
        t = "processlist";
        a = "toggle";
      };
      noctalia = {
        t = "controlCenter";
        a = "toggle";
      };
    };
    "XF86AudioRaiseVolume" = {
      locked = true;
      dms = {
        t = "audio";
        a = "increment";
        args = [ "5" ];
      };
      noctalia = {
        t = "volume";
        a = "increase";
      };
    };
    "XF86AudioLowerVolume" = {
      locked = true;
      dms = {
        t = "audio";
        a = "decrement";
        args = [ "5" ];
      };
      noctalia = {
        t = "volume";
        a = "decrease";
      };
    };
    "XF86AudioMute" = {
      locked = true;
      dms = {
        t = "audio";
        a = "mute";
      };
      noctalia = {
        t = "volume";
        a = "muteOutput";
      };
    };
    "XF86AudioMicMute" = {
      locked = true;
      dms = {
        t = "audio";
        a = "micmute";
      };
      noctalia = {
        t = "volume";
        a = "muteInput";
      };
    };
    "XF86MonBrightnessUp" = {
      locked = true;
      dms = {
        t = "brightness";
        a = "increment";
        args = [
          "10"
          "backlight:amdgpu_bl1"
        ];
      };
      noctalia = {
        t = "brightness";
        a = "increase";
      };
    };
    "XF86MonBrightnessDown" = {
      locked = true;
      dms = {
        t = "brightness";
        a = "decrement";
        args = [
          "10"
          "backlight:amdgpu_bl1"
        ];
      };
      noctalia = {
        t = "brightness";
        a = "decrease";
      };
    };
  };

  mkAction =
    bind:
    if isDms then
      {
        spawn = [
          "qs"
          "ipc"
          "--any-display"
          "-p"
          "${dms-pkg}/share/quickshell/dms"
          "call"
          bind.dms.t
          bind.dms.a
        ]
        ++ (bind.dms.args or [ ]);
      }
    else if isNoctalia then
      { spawn-sh = "noctalia-shell ipc call ${bind.noctalia.t} ${bind.noctalia.a}"; }
    else
      { spawn = [ "true" ]; };
in
lib.mkIf (quickshell != "none") {
  programs.niri.settings.binds = lib.mapAttrs (
    _: bind:
    {
      action = mkAction bind;
    }
    // lib.optionalAttrs (bind ? title) { hotkey-overlay.title = bind.title; }
    // lib.optionalAttrs (bind.locked or false) { allow-when-locked = true; }
  ) shellBinds;
}
