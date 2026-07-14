{ inputs, ... }:
{
  flake.modules.homeManager.noctalia =
    {
      self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.noctalia;
      theme = self.themes.${self.theme};

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
          spawn = noctalia bind.cmd;
        }
        // lib.optionalAttrs (bind ? title) { _props.hotkey-overlay-title = bind.title; }
        // lib.optionalAttrs (bind.locked or false) { _props.allow-when-locked = true; }
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
        # python3: kcolorscheme template apply.py post-hook (merges scheme into kdeglobals)
        home.packages = [
          pkgs.ddcutil
          pkgs.python3
          # fosskar/displays plugin: mirroring + drag-arrange fallback
          pkgs.wl-mirror
          pkgs.wdisplays
        ];

        wayland.windowManager.niri.settings = {
          binds = shellNiriBinds;
          window-rule = [
            {
              match = [ { _props.app-id = "dev.noctalia.Noctalia.Settings"; } ];
              open-floating = true;
              default-column-width = {
                fixed = 1080;
              };
              default-window-height = {
                fixed = 920;
              };
            }
          ];
          debug.honor-xdg-activation-with-invalid-serial = [ true ];
        };

        programs.noctalia = {
          enable = lib.mkDefault true;
          systemd.enable = lib.mkDefault true;
          customPalettes.grey-teal = palette;

          settings = {
            shell = {
              launch_apps_as_systemd_services = lib.mkDefault true;
              lang = lib.mkDefault "en";
              font_family = lib.mkDefault theme.fonts.sans;
              date_format = lib.mkDefault "%d.%m.%y";
              polkit_agent = lib.mkDefault true;
              screen_time_enabled = lib.mkDefault true;
              screen_corners.enabled = lib.mkDefault true;
              niri_overview_type_to_launch_enabled = lib.mkDefault true;
              greeter_sync.auto_sync = lib.mkDefault true;
              panel = {
                transparency_mode = lib.mkDefault "soft";
                open_near_click_control_center = lib.mkDefault true;
                session_placement = lib.mkDefault "floating";
                session_position = lib.mkDefault "center";
              };
            };

            osd = {
              position = lib.mkDefault "center_right";
              orientation = lib.mkDefault "vertical";
              background_opacity = lib.mkDefault 0.80;
              kinds = {
                lock_keys = lib.mkDefault false;
                keyboard_layout = lib.mkDefault false;
                media = lib.mkDefault false;
              };
            };

            theme = {
              source = lib.mkDefault "custom";
              custom_palette = lib.mkDefault "grey-teal";
              templates = {
                builtin_ids = [
                  "niri"
                  "qt"
                  "kcolorscheme"
                  "gtk4"
                  "btop"
                  "gtk3"
                  "wezterm"
                ];
                community_ids = [
                  "zathura"
                  "yazi"
                  "papirus-icons"
                ];
              };
            };

            bar = {
              order = [ "main" ];
              main = {
                enabled = lib.mkDefault true;
                background_opacity = lib.mkDefault 0.7;
                margin_ends = lib.mkDefault 10;
                margin_edge = lib.mkDefault 5;
                widget_spacing = lib.mkDefault 10;
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
                  "voxtype"
                  "input-volume"
                  "output-volume"
                  "displays"
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
              enabled = lib.mkDefault true;
            };

            plugins = {
              enabled = [
                "fosskar/voxtype"
                "fosskar/displays"
              ];
              source = [
                {
                  kind = "path";
                  name = "nixfiles";
                  location = ./plugins;
                }
              ];
            };

            widget = {
              voxtype = {
                type = "fosskar/voxtype:status";
              };
              displays = {
                type = "fosskar/displays:indicator";
              };
              clock = {
                anchor = lib.mkDefault true;
                format = lib.mkDefault "{:%H:%M}\\n{:%d.%m.%y}";
              };
              workspaces = {
                display = lib.mkDefault "name";
                hide_when_empty = lib.mkDefault true;
                empty_color = lib.mkDefault "on_surface_variant";
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
              brightness.show_label = lib.mkDefault false;
              tray-volume-spacer = {
                type = "spacer";
                length = lib.mkDefault 20;
              };
              tray.drawer = lib.mkDefault false;
              network.show_label = lib.mkDefault false;
              notifications.hide_when_no_unread = lib.mkDefault false;
              session.color = lib.mkDefault "error";
            };

            idle.behavior = {
              screen-off = {
                enabled = lib.mkDefault true;
                timeout = lib.mkDefault 300;
                action = "screen_off";
              };
              lock = {
                enabled = lib.mkDefault true;
                timeout = lib.mkDefault 1800;
                action = "lock";
              };
              suspend = {
                enabled = lib.mkDefault true;
                timeout = lib.mkDefault 3600;
                action = "suspend";
                lock_before_suspend = lib.mkDefault true;
              };
            };

            battery.device.hidpp_battery_0.warning_threshold = lib.mkDefault 15;

            calendar = {
              enabled = lib.mkDefault true;
              refresh_minutes = lib.mkDefault 15;
              account.opencloud = {
                type = "caldav";
                provider = "custom";
                name = "opencloud";
                server_url = "https://opencloud.${self.domains.local}/caldav/";
              };
            };

            lockscreen = {
              allow_empty_password = lib.mkDefault true;
              blurred_desktop = lib.mkDefault true;
              tint_intensity = lib.mkDefault 0.50;
            };

            lockscreen_widgets = {
              enabled = lib.mkDefault true;
              widget.clock_main = {
                type = "clock";
                output = "DP-1";
                cx = 1720.0;
                cy = 360.0;
                rotation = 0.0;
                settings.format = "{:%H:%M}";
              };
              widget.weather_main = {
                type = "weather";
                output = "DP-1";
                cx = 1720.0;
                cy = 540.0;
                rotation = 0.0;
              };
            };

            location.auto_locate = lib.mkDefault true;

            wallpaper.directory = lib.mkDefault "${config.home.homeDirectory}/Pictures/Wallpapers";

            weather = {
              enabled = lib.mkDefault true;
            };

            notification = {
              position = lib.mkDefault "top_right";
              background_opacity = lib.mkDefault 0.80;
            };

            hooks = {
              session_locked = toString lockSecrets;
              session_unlocked = "kwallet-tpm-unlock $HOME/.config/kwallet-tpm/password.cred";
            };
          };
        };

        # fosskar/displays saves ad-hoc kanshi profiles into this mutable file —
        # deliberate runtime state, not drift; declarative profiles stay in
        # services.kanshi.settings. mkBefore: kanshi applies the first matching
        # profile, so UI-saved layouts shadow declarative ones for the same
        # monitor set.
        services.kanshi.settings = lib.mkBefore [
          { include = "${config.xdg.configHome}/kanshi/noctalia.conf"; }
        ];

        # kanshi fails to start when an included file is missing; seed it empty.
        home.activation.seedNoctaliaKanshiConf = lib.mkIf config.services.kanshi.enable (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            if [ ! -f "${config.xdg.configHome}/kanshi/noctalia.conf" ]; then
              run mkdir -p "${config.xdg.configHome}/kanshi"
              run touch "${config.xdg.configHome}/kanshi/noctalia.conf"
            fi
          ''
        );
      };
    };
}
