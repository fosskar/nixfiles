{
  config,
  inputs,
  pkgs,
  ...
}:
{
  #xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs.niri.settings = {
    # workspace configuration
    workspaces = {
      primary = {
        name = "primary";
        open-on-output = "DP-1";
      };
      secondary = {
        name = "secondary";
        open-on-output = "HDMI-A-2";
      };
      gaming = {
        name = "gaming";
        open-on-output = "DP-1";
        # per-workspace layout overrides - uncomment after niri-flake supports it
        # layout = {
        #   gaps = 0;
        #   border.enable = false;
        #   focus-ring.enable = false;
        #   shadow.enable = false;
        # };
      };
    };

    # input configuration
    input = {
      mod-key = "Super";
      mod-key-nested = "Alt";

      focus-follows-mouse.enable = true;
      warp-mouse-to-focus.enable = true;
      workspace-auto-back-and-forth = true;

      keyboard.xkb = {
        layout = "de";
      };

      touchpad.enable = false;
      trackpoint.enable = false;
      trackball.enable = false;
      tablet.enable = false;
      touch.enable = false;

      mouse = {
        accel-profile = "flat";
      };
    };

    # prefer server-side decorations
    prefer-no-csd = true;

    # environment variables
    environment = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
      OZONE_PLATFORM = "wayland";
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "niri";
      GDK_BACKEND = "wayland,x11,*";
      CLUTTER_BACKEND = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = "qt6ct";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    };

    # output configuration
    outputs = {
      "DP-1" = {
        focus-at-startup = true;
        mode = {
          width = 3440;
          height = 1440;
          refresh = 164.900;
        };
        scale = 1.0;
        transform.rotation = 0;
        position = {
          x = 0;
          y = 0;
        };
      };

      "HDMI-A-2" = {
        mode = {
          width = 1920;
          height = 1080;
          refresh = 239.761;
        };
        scale = 1.0;
        transform.rotation = 270;
        position = {
          x = 3440;
          y = 0;
        };
      };
    };

    # layout configuration
    layout = {
      gaps = 8;
      background-color = "transparent";
      always-center-single-column = true;
      center-focused-column = "never";

      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66666; }
        { proportion = 1.0; }
      ];

      preset-window-heights = [
        { proportion = 0.5; }
        { proportion = 1.0; }
      ];

      # windows open at 33% width by default
      default-column-width = {
        proportion = 0.33333;
      };

      focus-ring = {
        enable = false;
        width = 2;
        active.color = "#ffa420";
        inactive.color = "#505050";
      };

      border = {
        enable = true;
        width = 1;
        urgent.color = "#9b0000";
        inactive.color = "transparent";
        active.gradient = {
          from = "#76D493";
          to = "#5B957B";
          angle = 180;
          relative-to = "workspace-view";
        };
      };

      shadow.enable = true;
    };

    # animations
    animations = {
      slowdown = 2.0; # 2x slower, adjust to taste
    };

    # startup commands
    spawn-at-startup = [
      { sh = "steam -silent"; }
      { command = [ "element-desktop" ]; }
    ];

    # hotkey overlay
    hotkey-overlay = {
      skip-at-startup = true;
    };

    # overview
    overview = {
      zoom = 0.5;
      backdrop-color = "#242424";
    };

    # window rules
    window-rules = [
      # browsers/editors at 50% width
      {
        matches = [
          { app-id = "^zen"; }
          { app-id = "^firefox"; }
          { app-id = "^chromium"; }
          { app-id = "^dev\\.zed\\.Zed$"; }
          { app-id = "^zeditor$"; }
        ];
        default-column-width = {
          proportion = 0.5;
        };
      }
      # element to secondary workspace
      {
        matches = [
          { app-id = "^Element$"; }
        ];
        open-on-workspace = "secondary";
      }
      {
        matches = [
          {
            app-id = "^zen$";
            title = "^Picture-in-Picture$";
          }
        ];
        open-floating = true;
      }
      {
        matches = [
          {
            at-startup = true;
            app-id = "^steam$";
          }
        ];
        open-on-workspace = "secondary";
      }
      {
        matches = [
          { app-id = "^steam$"; }
        ];
        open-maximized = true;
      }
      {
        matches = [
          {
            app-id = "steam";
            title = "^notificationtoasts_\\d+_desktop$";
          }
        ];
        default-floating-position = {
          x = 10;
          y = 10;
          relative-to = "bottom-right";
        };
      }
      # float common dialogs (from hyprland config)
      {
        matches = [
          { app-id = "^Pinentry-gtk$"; }
          { app-id = "^xdg-desktop-portal-gtk"; }
          { app-id = "^hyprpolkitagent$"; }
          { title = "^Open Files$"; }
          { title = "^File Upload$"; }
          { title = "^File Operation Progress$"; }
          { title = "^MainPicker$"; }
          { title = ".*Bitwarden.*"; }
        ];
        open-floating = true;
      }
      # webcord/ts3 to steam workspace (secondary monitor)
      {
        matches = [
          { app-id = "^WebCord$"; }
          { app-id = "^webcord$"; }
          { title = "^TeamSpeak 3$"; }
        ];
        open-on-workspace = "secondary";
      }
      {
        matches = [
          { app-id = "^org\\.keepassxc\\.KeePassXC$"; }
          { app-id = "^org\\.gnome\\.World\\.Secrets$"; }
        ];
        block-out-from = "screen-capture";
      }
      # gaming workspace window rule - uncomment after niri-flake supports on-workspace matcher
      # {
      #   matches = [
      #     { on-workspace = "gaming"; }
      #   ];
      #   geometry-corner-radius = {
      #     top-left = 0.0;
      #     top-right = 0.0;
      #     bottom-left = 0.0;
      #     bottom-right = 0.0;
      #   };
      #   animations.window-open.enable = false;
      #   animations.window-close.enable = false;
      #   animations.window-resize.enable = false;
      # }
      {
        matches = [ { } ]; # match all windows
        opacity = 1.0; # for toggle-window-rule-opacity
        draw-border-with-background = false;
        geometry-corner-radius = {
          top-left = 10.0;
          top-right = 10.0;
          bottom-left = 10.0;
          bottom-right = 10.0;
        };
        clip-to-geometry = true;
      }
    ];

    # keybindings
    binds =
      with config.lib.niri.actions;
      let
        dms-pkg = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
        dms-ipc = spawn "qs" "ipc" "--any-display" "-p" "${dms-pkg}/share/quickshell/dms" "call";
      in
      {
        # help overlay
        "Mod+Shift+Slash".action = {
          show-hotkey-overlay = [ ];
        };

        # program launches
        "Mod+T".action = {
          spawn = "ghostty";
        };
        "Mod+E".action = {
          spawn = "yazi";
        };
        "Mod+W".action = {
          spawn = "zen";
        };
        "Mod+Z".action = {
          spawn = "zeditor";
        };
        "Mod+P".action = {
          spawn = "ts3client";
        };
        "Mod+D".action = {
          spawn = "webcord";
        };

        #"Mod+Space".action = {
        #  spawn-sh = "noctalia-shell ipc call launcher toggle";
        #};

        "Mod+Space" = {
          action = dms-ipc "spotlight" "toggle";
          hotkey-overlay.title = "Toggle Application Launcher";
        };
        "Mod+N" = {
          action = dms-ipc "notepad" "toggle";
          hotkey-overlay.title = "Toggle Notepad";
        };
        "Mod+M" = {
          action = dms-ipc "processlist" "toggle";
          hotkey-overlay.title = "Toggle Process List";
        };
        "Mod+B" = {
          action = dms-ipc "clipboard" "toggle";
          hotkey-overlay.title = "Toggle Clipboard Manager";
        };
        "Mod+Shift+L" = {
          action = dms-ipc "lock" "lock";
          hotkey-overlay.title = "Toggle Lock Screen";
        };
        "Mod+X" = {
          action = dms-ipc "powermenu" "toggle";
          hotkey-overlay.title = "Toggle Power Menu";
        };
        "XF86AudioRaiseVolume" = {
          allow-when-locked = true;
          action = dms-ipc "audio" "increment" "5";
        };
        "XF86AudioLowerVolume" = {
          allow-when-locked = true;
          action = dms-ipc "audio" "decrement" "5";
        };
        "XF86AudioMute" = {
          allow-when-locked = true;
          action = dms-ipc "audio" "mute";
        };
        "XF86AudioMicMute" = {
          allow-when-locked = true;
          action = dms-ipc "audio" "micmute";
        };

        # audio controls
        #"XF86AudioRaiseVolume" = {
        #  action = {
        #    spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
        #  };
        #  allow-when-locked = true;
        #};
        #"XF86AudioLowerVolume" = {
        #  action = {
        #    spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
        #  };
        #  allow-when-locked = true;
        #};
        #"XF86AudioMute" = {
        #  action = {
        #    spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        #  };
        #  allow-when-locked = true;
        #};
        #"XF86AudioMicMute" = {
        #  action = {
        #    spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        #  };
        #  allow-when-locked = true;
        #};
        "XF86AudioPlay" = {
          action = {
            spawn-sh = "playerctl play-pause";
          };
          allow-when-locked = true;
        };
        "XF86AudioStop" = {
          action = {
            spawn-sh = "playerctl stop";
          };
          allow-when-locked = true;
        };
        "XF86AudioPrev" = {
          action = {
            spawn-sh = "playerctl previous";
          };
          allow-when-locked = true;
        };
        "XF86AudioNext" = {
          action = {
            spawn-sh = "playerctl next";
          };
          allow-when-locked = true;
        };

        # brightness controls
        "XF86MonBrightnessUp" = {
          action = {
            spawn = [
              "brightnessctl"
              "--class=backlight"
              "set"
              "+10%"
            ];
          };
          allow-when-locked = true;
        };
        "XF86MonBrightnessDown" = {
          action = {
            spawn = [
              "brightnessctl"
              "--class=backlight"
              "set"
              "10%-"
            ];
          };
          allow-when-locked = true;
        };

        # window management
        "Mod+O" = {
          action = {
            toggle-overview = [ ];
          };
          repeat = false;
        };
        "Mod+Q" = {
          action = {
            close-window = [ ];
          };
          repeat = false;
        };

        # focus movement
        "Mod+Left".action = {
          focus-column-left = [ ];
        };
        "Mod+Down".action = {
          focus-window-down = [ ];
        };
        "Mod+Up".action = {
          focus-window-up = [ ];
        };
        "Mod+Right".action = {
          focus-column-right = [ ];
        };
        "Mod+H".action = {
          focus-column-left = [ ];
        };
        "Mod+J".action = {
          focus-window-down = [ ];
        };
        "Mod+K".action = {
          focus-window-up = [ ];
        };
        "Mod+L".action = {
          focus-column-right = [ ];
        };

        # window movement
        "Mod+Ctrl+Left".action = {
          move-column-left = [ ];
        };
        "Mod+Ctrl+Down".action = {
          move-window-down = [ ];
        };
        "Mod+Ctrl+Up".action = {
          move-window-up = [ ];
        };
        "Mod+Ctrl+Right".action = {
          move-column-right = [ ];
        };
        "Mod+Ctrl+H".action = {
          move-column-left = [ ];
        };
        "Mod+Ctrl+J".action = {
          move-window-down = [ ];
        };
        "Mod+Ctrl+K".action = {
          move-window-up = [ ];
        };
        "Mod+Ctrl+L".action = {
          move-column-right = [ ];
        };

        # column focus
        "Mod+Home".action = {
          focus-column-first = [ ];
        };
        "Mod+End".action = {
          focus-column-last = [ ];
        };
        "Mod+Ctrl+Home".action = {
          move-column-to-first = [ ];
        };
        "Mod+Ctrl+End".action = {
          move-column-to-last = [ ];
        };

        # monitor focus (left/right)
        "Mod+Shift+Left".action = {
          focus-monitor-left = [ ];
        };
        "Mod+Shift+Right".action = {
          focus-monitor-right = [ ];
        };
        # workspace switching (up/down)
        "Mod+Shift+Up".action = {
          focus-workspace-up = [ ];
        };
        "Mod+Shift+Down".action = {
          focus-workspace-down = [ ];
        };

        # move to monitor
        "Mod+Shift+Ctrl+Left".action = {
          move-column-to-monitor-left = [ ];
        };
        "Mod+Shift+Ctrl+Down".action = {
          move-column-to-monitor-down = [ ];
        };
        "Mod+Shift+Ctrl+Up".action = {
          move-column-to-monitor-up = [ ];
        };
        "Mod+Shift+Ctrl+Right".action = {
          move-column-to-monitor-right = [ ];
        };
        "Mod+Shift+Ctrl+H".action = {
          move-column-to-monitor-left = [ ];
        };
        "Mod+Shift+Ctrl+J".action = {
          move-column-to-monitor-down = [ ];
        };
        "Mod+Shift+Ctrl+K".action = {
          move-column-to-monitor-up = [ ];
        };
        "Mod+Shift+Ctrl+L".action = {
          move-column-to-monitor-right = [ ];
        };

        # workspace navigation
        "Mod+Page_Down".action = {
          focus-workspace-down = [ ];
        };
        "Mod+Page_Up".action = {
          focus-workspace-up = [ ];
        };
        "Mod+U".action = {
          focus-workspace-down = [ ];
        };
        "Mod+I".action = {
          focus-workspace-up = [ ];
        };
        "Mod+Ctrl+Page_Down".action = {
          move-column-to-workspace-down = [ ];
        };
        "Mod+Ctrl+Page_Up".action = {
          move-column-to-workspace-up = [ ];
        };
        "Mod+Ctrl+U".action = {
          move-column-to-workspace-down = [ ];
        };
        "Mod+Ctrl+I".action = {
          move-column-to-workspace-up = [ ];
        };

        "Mod+Shift+Page_Down".action = {
          move-workspace-down = [ ];
        };
        "Mod+Shift+Page_Up".action = {
          move-workspace-up = [ ];
        };
        "Mod+Shift+U".action = {
          move-workspace-down = [ ];
        };
        "Mod+Shift+I".action = {
          move-workspace-up = [ ];
        };

        # mouse wheel column scrolling (horizontal)
        "Mod+WheelScrollDown" = {
          action = {
            focus-column-right = [ ];
          };
          cooldown-ms = 150;
        };
        "Mod+WheelScrollUp" = {
          action = {
            focus-column-left = [ ];
          };
          cooldown-ms = 150;
        };
        # mouse wheel workspace switching
        "Mod+Ctrl+WheelScrollDown" = {
          action = {
            focus-workspace-down = [ ];
          };
          cooldown-ms = 150;
        };
        "Mod+Ctrl+WheelScrollUp" = {
          action = {
            focus-workspace-up = [ ];
          };
          cooldown-ms = 150;
        };

        # mouse wheel column scrolling
        "Mod+WheelScrollRight".action = {
          focus-column-right = [ ];
        };
        "Mod+WheelScrollLeft".action = {
          focus-column-left = [ ];
        };
        "Mod+Ctrl+WheelScrollRight".action = {
          move-column-right = [ ];
        };
        "Mod+Ctrl+WheelScrollLeft".action = {
          move-column-left = [ ];
        };

        "Mod+Shift+WheelScrollDown".action = {
          focus-column-right = [ ];
        };
        "Mod+Shift+WheelScrollUp".action = {
          focus-column-left = [ ];
        };
        "Mod+Ctrl+Shift+WheelScrollDown".action = {
          move-column-right = [ ];
        };
        "Mod+Ctrl+Shift+WheelScrollUp".action = {
          move-column-left = [ ];
        };

        # workspace number bindings
        "Mod+1".action = {
          focus-workspace = 1;
        };
        "Mod+2".action = {
          focus-workspace = 2;
        };
        "Mod+3".action = {
          focus-workspace = 3;
        };
        "Mod+4".action = {
          focus-workspace = 4;
        };
        "Mod+5".action = {
          focus-workspace = 5;
        };
        "Mod+6".action = {
          focus-workspace = 6;
        };
        "Mod+7".action = {
          focus-workspace = 7;
        };
        "Mod+8".action = {
          focus-workspace = 8;
        };
        "Mod+9".action = {
          focus-workspace = 9;
        };
        "Mod+Ctrl+1".action = {
          move-column-to-workspace = 1;
        };
        "Mod+Ctrl+2".action = {
          move-column-to-workspace = 2;
        };
        "Mod+Ctrl+3".action = {
          move-column-to-workspace = 3;
        };
        "Mod+Ctrl+4".action = {
          move-column-to-workspace = 4;
        };
        "Mod+Ctrl+5".action = {
          move-column-to-workspace = 5;
        };
        "Mod+Ctrl+6".action = {
          move-column-to-workspace = 6;
        };
        "Mod+Ctrl+7".action = {
          move-column-to-workspace = 7;
        };
        "Mod+Ctrl+8".action = {
          move-column-to-workspace = 8;
        };
        "Mod+Ctrl+9".action = {
          move-column-to-workspace = 9;
        };

        # window manipulation
        "Mod+BracketLeft".action = {
          consume-or-expel-window-left = [ ];
        };
        "Mod+BracketRight".action = {
          consume-or-expel-window-right = [ ];
        };
        "Mod+Comma".action = {
          consume-window-into-column = [ ];
        };
        "Mod+Period".action = {
          expel-window-from-column = [ ];
        };
        # sizing
        "Mod+R".action = {
          switch-preset-column-width = [ ];
        };
        "Mod+Shift+R".action = {
          switch-preset-window-height = [ ];
        };
        "Mod+Ctrl+R".action = {
          reset-window-height = [ ];
        };
        "Mod+F".action = {
          fullscreen-window = [ ];
        };
        "Mod+Shift+F".action = {
          maximize-column = [ ];
        };
        "Mod+Ctrl+F".action = {
          expand-column-to-available-width = [ ];
        };

        # centering
        "Mod+C".action = {
          center-column = [ ];
        };
        "Mod+Ctrl+C".action = {
          center-visible-columns = [ ];
        };

        # manual sizing
        "Mod+Minus".action = {
          set-column-width = "-10%";
        };
        "Mod+Plus".action = {
          set-column-width = "+10%";
        };
        "Mod+Shift+Minus".action = {
          set-window-height = "-10%";
        };
        "Mod+Shift+Plus".action = {
          set-window-height = "+10%";
        };

        # floating
        "Mod+V".action = {
          toggle-window-floating = [ ];
        };
        "Mod+Shift+V".action = {
          switch-focus-between-floating-and-tiling = [ ];
        };

        # transparency toggle
        "Mod+A".action = {
          toggle-window-rule-opacity = [ ];
        };

        # screenshots
        "Print".action = {
          screenshot = [ ];
        };
        "Ctrl+Print".action = {
          screenshot-screen = [ ];
        };
        "Alt+Print".action = {
          screenshot-window = [ ];
        };

        # system
        "Mod+Escape" = {
          action = {
            toggle-keyboard-shortcuts-inhibit = [ ];
          };
          allow-inhibiting = false;
        };
        "Mod+Shift+E".action = {
          quit = [ ];
        };
        "Ctrl+Alt+Delete".action = {
          quit = [ ];
        };
        "Mod+Shift+P".action = {
          power-off-monitors = [ ];
        };
      };
  };
}
