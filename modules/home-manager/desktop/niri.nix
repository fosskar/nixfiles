{ inputs, ... }:
{
  flake.modules.homeManager.niri =
    {
      self,
      lib,
      pkgs,
      ...
    }:
    let
      theme = self.themes.${self.theme};

      toNodeList = lib.mapAttrsToList (name: value: value // { _args = [ (value.name or name) ]; });
      mapMatch = match: if match == { } then { } else { _props = match; };
      mapRule =
        rule:
        (removeAttrs rule [
          "matches"
          "excludes"
          "default-floating-position"
        ])
        // lib.optionalAttrs (rule ? matches) { match = map mapMatch rule.matches; }
        // lib.optionalAttrs (rule ? excludes) { exclude = map mapMatch rule.excludes; }
        // lib.optionalAttrs (rule ? default-floating-position) {
          default-floating-position._props = rule.default-floating-position;
        };
      mapBind =
        bind:
        (bind.action or { })
        // lib.optionalAttrs (bind ? allow-when-locked) {
          _props.allow-when-locked = bind.allow-when-locked;
        }
        // lib.optionalAttrs (bind ? allow-inhibiting) { _props.allow-inhibiting = bind.allow-inhibiting; }
        // lib.optionalAttrs (bind ? cooldown-ms) { _props.cooldown-ms = bind.cooldown-ms; }
        // lib.optionalAttrs (bind ? repeat) { _props.repeat = bind.repeat; }
        // lib.optionalAttrs (bind ? hotkey-overlay && bind.hotkey-overlay ? title) {
          _props.hotkey-overlay-title = bind.hotkey-overlay.title;
        }
        // lib.optionalAttrs (bind ? hotkey-overlay && (bind.hotkey-overlay.hidden or false)) {
          _props.hotkey-overlay-title = {
            _raw = "null";
          };
        };
      fromNiriFlakeSettings =
        settings:
        (removeAttrs settings [
          "workspaces"
          "binds"
          "spawn-at-startup"
          "window-rules"
          "layer-rules"
        ])
        // lib.optionalAttrs (settings ? workspaces) { workspace = toNodeList settings.workspaces; }
        // lib.optionalAttrs (settings ? binds) { binds = lib.mapAttrs (_: mapBind) settings.binds; }
        // lib.optionalAttrs (settings ? spawn-at-startup) (
          let
            shEntries = map (entry: [ entry.sh ]) (
              builtins.filter (entry: entry ? sh) settings.spawn-at-startup
            );
            argvEntries = map (entry: entry.argv or entry.command) (
              builtins.filter (entry: entry ? argv || entry ? command) settings.spawn-at-startup
            );
          in
          lib.optionalAttrs (shEntries != [ ]) { spawn-sh-at-startup = shEntries; }
          // lib.optionalAttrs (argvEntries != [ ]) { spawn-at-startup = argvEntries; }
        )
        // lib.optionalAttrs (settings ? window-rules) { window-rule = map mapRule settings.window-rules; }
        // lib.optionalAttrs (settings ? layer-rules) { layer-rule = map mapRule settings.layer-rules; };

    in
    {
      imports = [ inputs.niri-nix.homeModules.default ];

      wayland.windowManager.niri = {
        enable = true;
        package = inputs.niri-nix.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
      };

      home.packages = [
        pkgs.wl-clipboard
        pkgs.local.live-ocr
      ];

      wayland.windowManager.niri.settings = fromNiriFlakeSettings {
        # input configuration
        input = {
          focus-follows-mouse._props.max-scroll-amount = lib.mkDefault "0%";
          warp-mouse-to-focus = [ ];
          workspace-auto-back-and-forth = lib.mkDefault true;

          keyboard.xkb = {
            layout = lib.mkDefault "de";
          };

          mouse = {
            accel-profile = lib.mkDefault "flat";
          };

          touchpad = {
            natural-scroll = [ ];
            tap = [ ];
            dwt = [ ];
          };
        };

        # prefer server-side decorations
        prefer-no-csd = lib.mkDefault true;

        environment = {
          NIXOS_OZONE_WL = "1";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          QT_QPA_PLATFORMTHEME = "qt6ct";
        };

        layout = {
          gaps = lib.mkDefault 8;

          always-center-single-column = lib.mkDefault true;

          center-focused-column = lib.mkDefault "on-overflow";

          focus-ring = {
            width = lib.mkDefault 2;
            active-color = lib.mkDefault theme.dark.accent.primary;
            inactive-color = lib.mkDefault theme.dark.fg.dim;
          };

          shadow = {
            softness = lib.mkDefault 20;
            spread = lib.mkDefault 3;
            offset._props = {
              x = lib.mkDefault 0.0;
              y = lib.mkDefault 3.0;
            };
            color = lib.mkDefault "${theme.dark.bg.base}70";
          };
        };

        spawn-at-startup = [
          { sh = "sleep 3 && cinny"; }
        ];

        hotkey-overlay = {
          skip-at-startup = true;
        };

        overview = {
          backdrop-color = lib.mkDefault theme.dark.bg.elevated;
        };

        window-rules = [
          {
            matches = [ { } ]; # match all windows
            draw-border-with-background = false;
            background-effect = {
              blur = true;
              xray = false;
            };
            popups.background-effect.blur = true;
            geometry-corner-radius = 14.0;
            clip-to-geometry = true;
          }
          #steam notifications as floating at bottom right
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
          # live-ocr overlay
          {
            matches = [ { app-id = "^live-ocr$"; } ];
            open-floating = true;
          }
          #floating windows rules
          {
            matches = [
              {
                app-id = "^zen-beta$|^firefox$|^brave$";
                title = "^Picture-in-Picture$";
              }
              { app-id = "^Pinentry-.*$"; }
              { app-id = "^xdg-desktop-portal-.*$"; }
              { title = "^Open Files$"; }
              { title = "^File Upload$"; }
              { title = "^File Operation Progress$"; }
              { title = "^MainPicker$"; }
            ];
            open-floating = true;
          }
        ];

        layer-rules = [
          {
            matches = [ { namespace = "^noctalia-backdrop"; } ];
            place-within-backdrop = true;
          }
          {
            matches = [
              { namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|background|launcher-overlay)(-.*)?$"; }
            ];
            background-effect.xray = false;
            popups.background-effect.blur = true;
          }
          {
            matches = [
              { namespace = "^(pi-chat|quickshell)(-.+)?$"; }
            ];
            background-effect = {
              blur = true;
              xray = false;
            };
            popups.background-effect.blur = true;
          }
        ];

        binds = {
          # help overlay
          "Mod+Shift+Slash".action = {
            show-hotkey-overlay = [ ];
          };

          # toggle the spaces-os pi-chat panel
          "Mod+A" = {
            action.spawn = "pi-chat-toggle";
            hotkey-overlay.title = "Toggle pi-chat";
          };

          # toggle voxtype voice-to-text recording
          "Mod+S" = {
            action.spawn = [
              "voxtype"
              "record"
              "toggle"
            ];
            hotkey-overlay.title = "Toggle voice-to-text";
          };

          # program launches
          "Mod+T".action = {
            spawn = "ghostty";
          };
          "Mod+D".action = {
            spawn = "webcord";
          };

          # media controls (not shell-specific)
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

          # live-ocr
          "Mod+Shift+Print".action = {
            spawn = "live-ocr";
          };
          "Mod+Ctrl+Print".action = {
            spawn-sh = "live-ocr --fullscreen";
          };
          "Mod+Alt+Print".action = {
            spawn-sh = "live-ocr --window";
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
    };
}
