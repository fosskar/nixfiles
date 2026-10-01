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

      # home-manager's toKDL renders a plain list under a node name as anonymous
      # `- { }` children, so repeated nodes (rules, matches) go through _children
      matches = map (match: {
        match._props = match;
      });
    in
    {
      # home-manager's own wayland.windowManager.niri module; niri-nix supplies
      # only the package. portals and xwayland-satellite stay with the nixos
      # module, which already configures both for the whole session.
      wayland.windowManager.niri = {
        enable = true;
        package = inputs.niri-nix.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
        portalPackage = null;
        xwaylandSatellitePackage = null;
      };

      home.packages = [
        pkgs.wl-clipboard
        pkgs.local.live-ocr
        pkgs.local.niri-focus-or-spawn
      ];

      wayland.windowManager.niri.settings = {
        input = {
          focus-follows-mouse._props.max-scroll-amount = lib.mkDefault "0%";
          warp-mouse-to-focus._props.mode = lib.mkDefault "center-xy";
          workspace-auto-back-and-forth = lib.mkDefault true;
          keyboard.xkb.layout = lib.mkDefault "de";
          mouse.accel-profile = lib.mkDefault "flat";
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

        hotkey-overlay.skip-at-startup = true;

        overview.backdrop-color = lib.mkDefault theme.dark.bg.elevated;

        _children = [
          { spawn-sh-at-startup._args = [ "sleep 3 && element-desktop" ]; }

          # all windows
          {
            window-rule = {
              _children = matches [ { } ];
              draw-border-with-background = false;
              background-effect = {
                blur = true;
                xray = false;
              };
              popups.background-effect.blur = true;
              geometry-corner-radius = 14.0;
              clip-to-geometry = true;
            };
          }
          # steam notifications float at the bottom right
          {
            window-rule = {
              _children = matches [
                {
                  app-id = "steam";
                  title = "^notificationtoasts_\\d+_desktop$";
                }
              ];
              default-floating-position._props = {
                x = 10;
                y = 10;
                relative-to = "bottom-right";
              };
            };
          }
          # live-ocr overlay
          {
            window-rule = {
              _children = matches [ { app-id = "^live-ocr$"; } ];
              open-floating = true;
            };
          }
          # floating windows
          {
            window-rule = {
              _children = matches [
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
            };
          }

          {
            layer-rule = {
              _children = matches [ { namespace = "^noctalia-backdrop"; } ];
              place-within-backdrop = true;
            };
          }
          {
            layer-rule = {
              _children = matches [
                { namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|background|launcher-overlay)(-.*)?$"; }
              ];
              background-effect.xray = false;
              popups.background-effect.blur = true;
            };
          }
          {
            layer-rule = {
              _children = matches [ { namespace = "^(pi-chat|quickshell)(-.+)?$"; } ];
              background-effect = {
                blur = true;
                xray = false;
              };
              popups.background-effect.blur = true;
            };
          }
        ];

        binds = {
          "Mod+Shift+Slash".show-hotkey-overlay = [ ];

          "Mod+A" = {
            spawn = [
              "focus-or-spawn"
              "Hermes"
              "hermes-desktop-remote"
            ];
            _props.hotkey-overlay-title = "Open Hermes dashboard";
          };

          # program launches
          "Mod+T".spawn = "ghostty";
          "Mod+D".spawn = [
            "focus-or-spawn"
            "WebCord"
            "webcord"
          ];
          "Mod+Y".spawn = [
            "focus-or-spawn"
            "Element"
            "element-desktop"
          ];

          # media controls
          "XF86AudioPlay" = {
            spawn-sh = "playerctl play-pause";
            _props.allow-when-locked = true;
          };
          "XF86AudioStop" = {
            spawn-sh = "playerctl stop";
            _props.allow-when-locked = true;
          };
          "XF86AudioPrev" = {
            spawn-sh = "playerctl previous";
            _props.allow-when-locked = true;
          };
          "XF86AudioNext" = {
            spawn-sh = "playerctl next";
            _props.allow-when-locked = true;
          };

          # window management
          "Mod+O" = {
            toggle-overview = [ ];
            _props.repeat = false;
          };
          "Mod+Q" = {
            close-window = [ ];
            _props.repeat = false;
          };

          # focus movement
          "Mod+Left".focus-column-left = [ ];
          "Mod+Down".focus-window-down = [ ];
          "Mod+Up".focus-window-up = [ ];
          "Mod+Right".focus-column-right = [ ];
          "Mod+H".focus-column-left = [ ];
          "Mod+J".focus-window-down = [ ];
          "Mod+K".focus-window-up = [ ];
          "Mod+L".focus-column-right = [ ];

          # window movement
          "Mod+Ctrl+Left".move-column-left = [ ];
          "Mod+Ctrl+Down".move-window-down = [ ];
          "Mod+Ctrl+Up".move-window-up = [ ];
          "Mod+Ctrl+Right".move-column-right = [ ];
          "Mod+Ctrl+H".move-column-left = [ ];
          "Mod+Ctrl+J".move-window-down = [ ];
          "Mod+Ctrl+K".move-window-up = [ ];
          "Mod+Ctrl+L".move-column-right = [ ];

          # column focus
          "Mod+Home".focus-column-first = [ ];
          "Mod+End".focus-column-last = [ ];
          "Mod+Ctrl+Home".move-column-to-first = [ ];
          "Mod+Ctrl+End".move-column-to-last = [ ];

          # monitor focus (left/right), workspace switching (up/down)
          "Mod+Shift+Left".focus-monitor-left = [ ];
          "Mod+Shift+Right".focus-monitor-right = [ ];
          "Mod+Shift+Up".focus-workspace-up = [ ];
          "Mod+Shift+Down".focus-workspace-down = [ ];

          # move to monitor
          "Mod+Shift+Ctrl+Left".move-column-to-monitor-left = [ ];
          "Mod+Shift+Ctrl+Down".move-column-to-monitor-down = [ ];
          "Mod+Shift+Ctrl+Up".move-column-to-monitor-up = [ ];
          "Mod+Shift+Ctrl+Right".move-column-to-monitor-right = [ ];
          "Mod+Shift+Ctrl+H".move-column-to-monitor-left = [ ];
          "Mod+Shift+Ctrl+J".move-column-to-monitor-down = [ ];
          "Mod+Shift+Ctrl+K".move-column-to-monitor-up = [ ];
          "Mod+Shift+Ctrl+L".move-column-to-monitor-right = [ ];

          # workspace navigation
          "Mod+Page_Down".focus-workspace-down = [ ];
          "Mod+Page_Up".focus-workspace-up = [ ];
          "Mod+U".focus-workspace-down = [ ];
          "Mod+I".focus-workspace-up = [ ];
          "Mod+Ctrl+Page_Down".move-column-to-workspace-down = [ ];
          "Mod+Ctrl+Page_Up".move-column-to-workspace-up = [ ];
          "Mod+Ctrl+U".move-column-to-workspace-down = [ ];
          "Mod+Ctrl+I".move-column-to-workspace-up = [ ];
          "Mod+Shift+Page_Down".move-workspace-down = [ ];
          "Mod+Shift+Page_Up".move-workspace-up = [ ];
          "Mod+Shift+U".move-workspace-down = [ ];
          "Mod+Shift+I".move-workspace-up = [ ];

          # mouse wheel
          "Mod+WheelScrollDown" = {
            focus-column-right = [ ];
            _props.cooldown-ms = 150;
          };
          "Mod+WheelScrollUp" = {
            focus-column-left = [ ];
            _props.cooldown-ms = 150;
          };
          "Mod+Ctrl+WheelScrollDown" = {
            focus-workspace-down = [ ];
            _props.cooldown-ms = 150;
          };
          "Mod+Ctrl+WheelScrollUp" = {
            focus-workspace-up = [ ];
            _props.cooldown-ms = 150;
          };
          "Mod+WheelScrollRight".focus-column-right = [ ];
          "Mod+WheelScrollLeft".focus-column-left = [ ];
          "Mod+Ctrl+WheelScrollRight".move-column-right = [ ];
          "Mod+Ctrl+WheelScrollLeft".move-column-left = [ ];

          # window manipulation
          "Mod+BracketLeft".consume-or-expel-window-left = [ ];
          "Mod+BracketRight".consume-or-expel-window-right = [ ];
          "Mod+Comma".consume-window-into-column = [ ];
          "Mod+Period".expel-window-from-column = [ ];

          # sizing
          "Mod+R".switch-preset-column-width = [ ];
          "Mod+Shift+R".switch-preset-window-height = [ ];
          "Mod+Ctrl+R".reset-window-height = [ ];
          "Mod+F".fullscreen-window = [ ];
          "Mod+Shift+F".maximize-column = [ ];
          "Mod+Ctrl+F".expand-column-to-available-width = [ ];
          "Mod+Minus".set-column-width = "-10%";
          "Mod+Plus".set-column-width = "+10%";
          "Mod+Shift+Minus".set-window-height = "-10%";
          "Mod+Shift+Plus".set-window-height = "+10%";

          # centering
          "Mod+C".center-column = [ ];
          "Mod+Ctrl+C".center-visible-columns = [ ];

          # floating
          "Mod+V".toggle-window-floating = [ ];
          "Mod+Shift+V".switch-focus-between-floating-and-tiling = [ ];

          # screenshots
          "Print".screenshot = [ ];
          "Ctrl+Print".screenshot-screen = [ ];
          "Alt+Print".screenshot-window = [ ];

          # live-ocr
          "Mod+Shift+Print".spawn = "live-ocr";
          "Mod+Ctrl+Print".spawn-sh = "live-ocr --fullscreen";
          "Mod+Alt+Print".spawn-sh = "live-ocr --window";

          # system
          "Mod+Escape" = {
            toggle-keyboard-shortcuts-inhibit = [ ];
            _props.allow-inhibiting = false;
          };
          "Mod+Shift+E".quit = [ ];
          "Ctrl+Alt+Delete".quit = [ ];
          "Mod+Shift+P".power-off-monitors = [ ];
        }
        // lib.genAttrs' (lib.range 1 9) (n: lib.nameValuePair "Mod+${toString n}" { focus-workspace = n; })
        // lib.genAttrs' (lib.range 1 9) (
          n: lib.nameValuePair "Mod+Ctrl+${toString n}" { move-column-to-workspace = n; }
        );
      };
    };
}
