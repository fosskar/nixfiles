{ inputs, ... }:
{
  flake.modules.homeManager.noctalia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.noctalia;
      inherit (config) theme;

      lockSecrets = pkgs.writeShellScript "lock-secrets" ''
        ${pkgs.libsecret}/bin/secret-tool lock --collection=kdewallet 2>/dev/null || true
      '';

      noctalia =
        cmd:
        [
          (lib.getExe cfg.package)
          "msg"
        ]
        ++ (lib.splitString " " cmd);

      shellBinds = {
        "Mod+Space" = {
          title = "Toggle Launcher";
          cmd = "panel-toggle launcher";
        };
        "Mod+B" = {
          title = "Toggle Clipboard";
          cmd = "panel-toggle clipboard";
        };
        "Mod+X" = {
          title = "Toggle Power Menu";
          cmd = "panel-toggle session";
        };
        "Mod+Shift+L" = {
          title = "Lock Screen";
          cmd = "session lock";
        };
        "Mod+M" = {
          title = "Toggle Control Center";
          cmd = "panel-toggle control-center";
        };
        "XF86AudioRaiseVolume" = {
          locked = true;
          cmd = "volume-up";
        };
        "XF86AudioLowerVolume" = {
          locked = true;
          cmd = "volume-down";
        };
        "XF86AudioMute" = {
          locked = true;
          cmd = "volume-mute";
        };
        "XF86AudioMicMute" = {
          locked = true;
          cmd = "mic-mute";
        };
        "XF86MonBrightnessUp" = {
          locked = true;
          cmd = "brightness-up";
        };
        "XF86MonBrightnessDown" = {
          locked = true;
          cmd = "brightness-down";
        };
      };

      shellNiriBinds = lib.mapAttrs (
        _: bind:
        {
          action.spawn = noctalia bind.cmd;
        }
        // lib.optionalAttrs (bind ? title) { hotkey-overlay.title = bind.title; }
        // lib.optionalAttrs (bind.locked or false) { allow-when-locked = true; }
      ) shellBinds;

      mkPalette = mode: ansiNormalBlack: ansiNormalWhite: ansiBrightBlack: ansiBrightWhite: {
        mPrimary = mode.accent.primary;
        mOnPrimary = mode.bg.base;
        mSecondary = mode.accent.secondary;
        mOnSecondary = mode.bg.base;
        mTertiary = mode.accent.tertiary;
        mOnTertiary = mode.bg.base;
        mError = mode.semantic.error;
        mOnError = mode.bg.base;
        mSurface = mode.bg.base;
        mOnSurface = mode.fg.base;
        mSurfaceVariant = mode.bg.surface;
        mOnSurfaceVariant = mode.fg.muted;
        mOutline = mode.fg.dim;
        mShadow = mode.bg.base;
        mHover = mode.accent.primary;
        mOnHover = mode.bg.base;
        terminal = {
          background = mode.bg.base;
          foreground = mode.fg.base;
          cursor = mode.fg.base;
          cursorText = mode.bg.base;
          selectionBg = mode.fg.base;
          selectionFg = mode.bg.base;
          normal = {
            black = ansiNormalBlack;
            red = theme.ansi.normal.red;
            green = theme.ansi.normal.green;
            yellow = theme.ansi.normal.yellow;
            blue = theme.ansi.normal.blue;
            magenta = theme.ansi.normal.magenta;
            cyan = theme.ansi.normal.cyan;
            white = ansiNormalWhite;
          };
          bright = {
            black = ansiBrightBlack;
            red = theme.ansi.bright.red;
            green = theme.ansi.bright.green;
            yellow = theme.ansi.bright.yellow;
            blue = theme.ansi.bright.blue;
            magenta = theme.ansi.bright.magenta;
            cyan = theme.ansi.bright.cyan;
            white = ansiBrightWhite;
          };
        };
      };

      palette = {
        dark =
          mkPalette theme.dark theme.ansi.normal.black theme.ansi.normal.white theme.ansi.bright.black
            theme.ansi.bright.white;
        light =
          mkPalette theme.light theme.light.bg.base theme.light.fg.base theme.light.bg.overlay
            theme.dark.bg.elevated;
      };
    in
    {
      imports = [ inputs.noctalia.homeModules.default ];

      config = {
        home.packages = [ pkgs.ddcutil ];

        programs.niri.settings = {
          binds = shellNiriBinds;
          window-rules = [
            {
              matches = [ { app-id = "dev.noctalia.Noctalia.Settings"; } ];
              open-floating = true;
              default-column-width = {
                fixed = 1080;
              };
              default-window-height = {
                fixed = 920;
              };
            }
          ];
          debug.honor-xdg-activation-with-invalid-serial = true;
        };

        programs.noctalia = {
          enable = lib.mkDefault true;
          systemd.enable = lib.mkDefault true;
          customPalettes.grey-teal = palette;

          settings = {
            shell = {
              launch_apps_as_systemd_services = true;
              font_family = theme.fonts.sans;
              time_format = "{:%H:%M}";
              date_format = "%d.%m.%y";
              telemetry_enabled = false;
              polkit_agent = true;
              show_location = true;
              screen_corners.enabled = true;
              niri_overview_type_to_launch_enabled = true;
              panel = {
                background_blur = true;
                transparency_mode = "soft";
                open_near_click_control_center = true;
                session_placement = "centered";
              };
            };

            osd = {
              position = "center_right";
              orientation = "vertical";
              lock_keys = false;
            };

            theme = {
              mode = "dark";
              source = "custom";
              custom_palette = "grey-teal";
              templates = {
                enable_builtin_templates = true;
                enable_community_templates = true;
                builtin_ids = [
                  "niri"
                  "qt"
                  "gtk4"
                  "btop"
                  "gtk3"
                  "wezterm"
                ];
                community_ids = [
                  "zathura"
                  "yazi"
                ];
              };
            };

            bar = {
              order = [ "main" ];
              main = {
                position = "top";
                enabled = true;
                auto_hide = false;
                reserve_space = true;
                background_opacity = 0.7;
                attach_panels = true;
                capsule = false;
                margin_ends = 10;
                margin_edge = 5;
                widget_spacing = 10;
                start = [
                  "control-center"
                  "workspaces"
                  "disk"
                  "ram"
                  "cpu"
                  "cpu-temp"
                  "gpu-temp"
                ];
                center = [
                  "clock"
                  "weather"
                ];
                end = [
                  "tray"
                  "tray-volume-spacer"
                  "input-volume"
                  "output-volume"
                  "brightness"
                  "network"
                  "bluetooth"
                  "battery"
                  "notifications"
                  "caffeine"
                  "session"
                ];
              };
            };

            backdrop = {
              enabled = true;
            };

            widget = {
              clock = {
                anchor = true;
                format = "{:%H:%M}\\n{:%d.%m.%y}";
              };
              workspaces = {
                display = "name";
                hide_when_empty = true;
                empty_color = "on_surface_variant";
              };
              disk = {
                type = "sysmon";
                stat = "disk_pct";
              };
              ram = {
                type = "sysmon";
                stat = "ram_pct";
              };
              cpu = {
                type = "sysmon";
                stat = "cpu_usage";
              };
              cpu-temp = {
                type = "sysmon";
                stat = "cpu_temp";
              };
              gpu-temp = {
                type = "sysmon";
                stat = "gpu_temp";
              };
              input-volume = {
                type = "volume";
                device = "input";
              };
              output-volume = {
                type = "volume";
                device = "output";
              };
              brightness.show_label = false;
              tray-volume-spacer = {
                type = "spacer";
                length = 20;
              };
              tray.drawer = false;
              network.show_label = false;
              notifications.hide_when_no_unread = false;
              session.color = "error";
            };

            dock.enabled = false;
            desktop_widgets.enabled = false;

            idle.behavior = {
              screen-off = {
                enabled = true;
                timeout = 300;
                action = "screen_off";
              };
              lock = {
                enabled = true;
                timeout = 1800;
                action = "lock";
              };
              suspend = {
                enabled = true;
                timeout = 3600;
                action = "suspend";
                lock_before_suspend = true;
              };
            };

            system.monitor.enabled = true;

            wallpaper.directory = "${config.home.homeDirectory}/Pictures/Wallpapers";

            weather = {
              enabled = true;
              auto_locate = false;
              address = "Hamburg";
              unit = "metric";
            };

            notification = {
              enable_daemon = true;
              position = "top_right";
              background_opacity = 0.97;
            };

            audio = {
              enable_overdrive = false;
              enable_sounds = false;
            };

            hooks = {
              session_locked = toString lockSecrets;
              session_unlocked = "kwallet-tpm-unlock $HOME/.config/kwallet-tpm/password.cred";
            };
          };
        };
      };
    };
}
