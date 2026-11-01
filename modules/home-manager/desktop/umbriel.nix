{ inputs, ... }:
{
  flake.modules.homeManager.umbriel =
    {
      self,
      lib,
      pkgs,
      ...
    }:
    let
      theme = self.themes.${self.theme};
      live-ocr = lib.getExe pkgs.local.live-ocr;

      noRepeat = action: {
        inherit action;
        repeat = false;
      };
      whenLocked = action: {
        inherit action;
        allow_when_locked = true;
      };
      cooldown = action: {
        inherit action;
        cooldown_ms = 150;
      };
    in
    {
      imports = [ inputs.umbriel.homeModules.default ];

      home.packages = [ pkgs.local.focus-or-spawn ];

      programs.umbriel = {
        enable = true;

        settings = {
          general = {
            show_cheatsheet = false;
            autostart = [ "sleep 3 && element-desktop" ];
          };

          environment = {
            NIXOS_OZONE_WL = "1";
            QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          };

          input = {
            keyboard.layout = lib.mkDefault "de";
            mouse.accel_profile = lib.mkDefault "flat";
            touchpad = {
              tap = true;
              natural_scroll = true;
              disable_while_typing = true;
            };
            focus = {
              follows_mouse = lib.mkDefault true;
              follows_mouse_max_scroll = lib.mkDefault 0.0;
            };
            cursor.follows_focus = lib.mkDefault true;
          };

          workspaces.back_and_forth = lib.mkDefault true;

          layout = {
            gap = lib.mkDefault 8;
            scrolling.center_focused = lib.mkDefault "on_overflow";
          };

          appearance = {
            prefer_no_csd = true;
            border_width = lib.mkDefault 2;
            corner_radius = lib.mkDefault 14;
            shadow = {
              softness = lib.mkDefault 20;
              offset_x = lib.mkDefault 0;
              offset_y = lib.mkDefault 3;
            };
          };

          colors = {
            shadow = lib.mkDefault "${theme.dark.bg.base}70";
            border = {
              focused = lib.mkDefault theme.dark.accent.primary;
              unfocused = lib.mkDefault theme.dark.fg.dim;
            };
          };

          window_rule = [
            # all windows
            { blur = true; }
            {
              match.app_id = "^dev\\.noctalia\\.Noctalia(\\.Settings)?$";
              default_floating = true;
              default_floating_size_px = {
                width = 1080;
                height = 920;
              };
            }
            {
              match.title = "^notificationtoasts_\\d+_desktop$";
              match.app_id = "^steam$";
              default_position = {
                x = 10;
                y = 10;
                anchor = "bottom_right";
              };
            }
            {
              match.app_id = [
                "^live-ocr$"
                "^Pinentry-.*$"
                "^xdg-desktop-portal-.*$"
              ];
              default_floating = true;
            }
            {
              match.app_id = "^zen-beta$|^firefox$|^brave$";
              match.title = "^Picture-in-Picture$";
              default_floating = true;
            }
            {
              match.title = [
                "^Open Files$"
                "^File Upload$"
                "^File Operation Progress$"
                "^MainPicker$"
              ];
              default_floating = true;
            }
          ];

          layer_rule = [
            {
              match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd|desktop-widget-[^\"]*)$";
              blur = true;
              blur_ignore_alpha = 0.5;
              blur_popups = true;
            }
            # panels open over windows, so they blur live content instead of the cached wallpaper
            {
              match.namespace = "^noctalia-(notification|dock|panel|attached-panel|osd)$";
              blur_optimized = false;
            }
            {
              match.namespace = "^(pi-chat|quickshell)(-.+)?$";
              blur = true;
              blur_popups = true;
            }
          ];

          # defining keybinds replaces umbriel's built-in bind set
          keybinds = {
            "Mod+Shift+Slash" = "cheatsheet-toggle";

            # program launches
            "Mod+A" = noRepeat "spawn focus-or-spawn Hermes hermes-desktop-remote";
            "Mod+T" = noRepeat "spawn ghostty";
            "Mod+D" = noRepeat "spawn focus-or-spawn WebCord webcord";
            "Mod+Y" = noRepeat "spawn focus-or-spawn Element element-desktop";

            # noctalia shell, same binds as on niri
            "Mod+Space" = noRepeat "spawn noctalia msg panel-toggle launcher";
            "Mod+B" = noRepeat "spawn noctalia msg panel-toggle clipboard";
            "Mod+X" = noRepeat "spawn noctalia msg panel-toggle session";
            "Mod+Shift+L" = noRepeat "spawn noctalia msg session lock";
            "Mod+M" = noRepeat "spawn noctalia msg panel-toggle control-center";
            "XF86AudioRaiseVolume" = whenLocked "spawn noctalia msg volume-up";
            "XF86AudioLowerVolume" = whenLocked "spawn noctalia msg volume-down";
            "XF86AudioMute" = whenLocked "spawn noctalia msg volume-mute";
            "XF86AudioMicMute" = whenLocked "spawn noctalia msg mic-mute";
            "XF86MonBrightnessUp" = whenLocked "spawn noctalia msg brightness-up";
            "XF86MonBrightnessDown" = whenLocked "spawn noctalia msg brightness-down";

            # media controls
            "XF86AudioPlay" = whenLocked "spawn playerctl play-pause";
            "XF86AudioStop" = whenLocked "spawn playerctl stop";
            "XF86AudioPrev" = whenLocked "spawn playerctl previous";
            "XF86AudioNext" = whenLocked "spawn playerctl next";

            # window management
            "Mod+O" = noRepeat "overview-toggle";
            "Mod+Q" = noRepeat "window-close";

            # focus movement
            "Mod+Left" = "window-focus-left";
            "Mod+Down" = "window-focus-down";
            "Mod+Up" = "window-focus-up";
            "Mod+Right" = "window-focus-right";
            "Mod+H" = "window-focus-left";
            "Mod+J" = "window-focus-down";
            "Mod+K" = "window-focus-up";
            "Mod+L" = "window-focus-right";

            # window movement
            "Mod+Ctrl+Left" = "column-move-left";
            "Mod+Ctrl+Down" = "window-move-down";
            "Mod+Ctrl+Up" = "window-move-up";
            "Mod+Ctrl+Right" = "column-move-right";
            "Mod+Ctrl+H" = "column-move-left";
            "Mod+Ctrl+J" = "window-move-down";
            "Mod+Ctrl+K" = "window-move-up";
            "Mod+Ctrl+L" = "column-move-right";

            # column focus
            "Mod+Home" = "column-focus-first";
            "Mod+End" = "column-focus-last";
            "Mod+Ctrl+Home" = "column-move-to-first";
            "Mod+Ctrl+End" = "column-move-to-last";

            # monitor focus (left/right), workspace switching (up/down)
            "Mod+Shift+Left" = "output-focus-left";
            "Mod+Shift+Right" = "output-focus-right";
            "Mod+Shift+Up" = "workspace-previous";
            "Mod+Shift+Down" = "workspace-next";

            # move to monitor
            "Mod+Shift+Ctrl+Left" = "column-move-to-output-left";
            "Mod+Shift+Ctrl+Down" = "column-move-to-output-down";
            "Mod+Shift+Ctrl+Up" = "column-move-to-output-up";
            "Mod+Shift+Ctrl+Right" = "column-move-to-output-right";
            "Mod+Shift+Ctrl+H" = "column-move-to-output-left";
            "Mod+Shift+Ctrl+J" = "column-move-to-output-down";
            "Mod+Shift+Ctrl+K" = "column-move-to-output-up";
            "Mod+Shift+Ctrl+L" = "column-move-to-output-right";

            # workspace navigation
            "Mod+Page_Down" = "workspace-next";
            "Mod+Page_Up" = "workspace-previous";
            "Mod+U" = "workspace-next";
            "Mod+I" = "workspace-previous";
            "Mod+Ctrl+Page_Down" = "column-move-to-workspace-next";
            "Mod+Ctrl+Page_Up" = "column-move-to-workspace-previous";
            "Mod+Ctrl+U" = "column-move-to-workspace-next";
            "Mod+Ctrl+I" = "column-move-to-workspace-previous";
            "Mod+Shift+Page_Down" = "workspace-move-down";
            "Mod+Shift+Page_Up" = "workspace-move-up";
            "Mod+Shift+U" = "workspace-move-down";
            "Mod+Shift+I" = "workspace-move-up";

            # mouse wheel
            "Mod+WheelDown" = cooldown "window-focus-right";
            "Mod+WheelUp" = cooldown "window-focus-left";
            "Mod+Ctrl+WheelDown" = cooldown "workspace-next";
            "Mod+Ctrl+WheelUp" = cooldown "workspace-previous";
            "Mod+WheelRight" = "window-focus-right";
            "Mod+WheelLeft" = "window-focus-left";
            "Mod+Ctrl+WheelRight" = "column-move-right";
            "Mod+Ctrl+WheelLeft" = "column-move-left";

            # window manipulation
            "Mod+BracketLeft" = "window-consume-or-expel-left";
            "Mod+BracketRight" = "window-consume-or-expel-right";
            "Mod+Comma" = "window-consume-from-right";

            # sizing
            "Mod+R" = "window-cycle-primary-extent";
            "Mod+Shift+R" = "window-cycle-secondary-extent";
            "Mod+F" = noRepeat "window-toggle-fullscreen";
            "Mod+Shift+F" = noRepeat "window-toggle-maximize";
            "Mod+Minus" = "window-modify-primary-extent -0.1";
            "Mod+Plus" = "window-modify-primary-extent 0.1";
            "Mod+Shift+Minus" = "window-modify-secondary-extent -0.1";
            "Mod+Shift+Plus" = "window-modify-secondary-extent 0.1";

            # centering
            "Mod+C" = "column-center";

            # floating
            "Mod+V" = noRepeat "window-toggle-floating";
            "Mod+Shift+V" = noRepeat "window-focus-switch-floating";

            # screenshots; umbriel has no screenshot action
            "Print" = noRepeat "spawn noctalia msg screenshot-region";
            "Ctrl+Print" = noRepeat "spawn noctalia msg screenshot-fullscreen";
            "Alt+Print" = noRepeat "spawn noctalia msg screenshot-window";

            # live-ocr
            "Mod+Shift+Print" = noRepeat "spawn ${live-ocr}";
            "Mod+Ctrl+Print" = noRepeat "spawn ${live-ocr} --fullscreen";
            "Mod+Alt+Print" = noRepeat "spawn ${live-ocr} --window";

            # system
            "Mod+Escape" = {
              action = "shortcuts-inhibit-toggle";
              allow_when_inhibited = true;
              repeat = false;
            };
            "Mod+Shift+E" = noRepeat "session-quit";
            "Ctrl+Alt+Delete" = noRepeat "session-quit";
            "Mod+Shift+P" = noRepeat "dpms-off";
          }
          // lib.genAttrs' (lib.range 1 9) (
            n: lib.nameValuePair "Mod+${toString n}" "workspace-switch ${toString n}"
          )
          // lib.genAttrs' (lib.range 1 9) (
            n: lib.nameValuePair "Mod+Ctrl+${toString n}" "column-move-to-workspace ${toString n}"
          );
        };
      };
    };
}
