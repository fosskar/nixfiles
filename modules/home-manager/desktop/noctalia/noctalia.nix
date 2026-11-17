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
        "Alt+Tab" = {
          title = "Window Switcher";
          cmd = "window-switcher hold";
        };
        "Alt+Shift+Tab" = {
          title = "Window Switcher (reverse)";
          cmd = "window-switcher hold reverse";
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

      # palette format 2: keys are noctalia's color role names
      mkPalette = mode: ansi: {
        primary = mode.accent.primary;
        on_primary = mode.bg.base;
        secondary = mode.accent.secondary;
        on_secondary = mode.bg.base;
        tertiary = mode.accent.tertiary;
        on_tertiary = mode.bg.base;
        error = mode.semantic.error;
        on_error = mode.bg.base;
        surface = mode.bg.base;
        on_surface = mode.fg.base;
        surface_container = mode.bg.surface;
        on_surface_variant = mode.fg.muted;
        outline_variant = mode.fg.dim;
        shadow = mode.bg.base;
        hover = mode.accent.primary;
        on_hover = mode.bg.base;
        terminal = {
          background = mode.bg.base;
          foreground = mode.fg.base;
          cursor = mode.fg.base;
          cursor_text = mode.bg.base;
          selection_bg = mode.fg.base;
          selection_fg = mode.bg.base;
          inherit (ansi) normal bright;
        };
      };

      palette = {
        version = 2;
        dark = mkPalette theme.dark theme.ansi;
        light = mkPalette theme.light theme.light.ansi;
      };
    in
    {
      config = {
        # python3: kcolorscheme template apply.py post-hook (merges scheme into kdeglobals)
        home.packages = [
          pkgs.ddcutil
          pkgs.python3
          # fosskar/displays plugin: output control, mirroring, drag-arrange fallback
          pkgs.wlr-randr
          pkgs.wl-mirror
          pkgs.wdisplays
        ];

        wayland.windowManager.niri.settings = {
          binds = shellNiriBinds;
          _children = [
            {
              window-rule = {
                _children = [ { match._props.app-id = "dev.noctalia.Noctalia.Settings"; } ];
                open-floating = true;
                default-column-width = {
                  fixed = 1080;
                };
                default-window-height = {
                  fixed = 920;
                };
              };
            }
          ];
          debug.honor-xdg-activation-with-invalid-serial = [ true ];
        };

        # home-manager's noctalia service lacks noctalia's own Type=notify, which
        # makes units ordered after it wait until the tray watcher is up
        systemd.user.services.noctalia.Service.Type = "notify";

        programs.noctalia = {
          enable = lib.mkDefault true;
          package = pkgs.noctalia;
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
              umbriel_overview_type_to_launch_enabled = lib.mkDefault true;
              umbriel_audio_provider_enabled = lib.mkDefault true;
              settings_show_advanced = lib.mkDefault true;
              readline_shortcuts = lib.mkDefault true;
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
              # sliders are vertical, so their placement comes from position_vertical
              position_vertical = lib.mkDefault "center_right";
              orientation = lib.mkDefault "vertical";
              background_opacity = lib.mkDefault 0.80;
              follow_focused_output = lib.mkDefault true;
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
                # niri, gtk3/gtk4, btop and wezterm are themed in nix; their
                # templates rewrite those home-manager-owned files at runtime
                builtin_ids = [
                  "qt"
                  "kcolorscheme"
                ];
                community_ids = [
                  "zathura"
                  "papirus-icons"
                ];
                user.luciole = {
                  input_path = "${
                    inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default
                  }/share/luciole/templates/colors.toml";
                  output_path = "$XDG_CONFIG_HOME/luciole/colors.toml";
                };
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
              displays = {
                type = "fosskar/displays:indicator";
              };
              clock = {
                anchor = lib.mkDefault true;
                format = lib.mkDefault "{:%H:%M}\\n{:%d.%m.%y}";
              };
              workspaces = {
                label_source = lib.mkDefault "name";
                hide_when_empty = lib.mkDefault true;
                empty_color = lib.mkDefault "on_surface_variant";
              };
              disk = {
                type = "sysmon";
                stat = "disk_used_pct";
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
                peek = lib.mkDefault true;
              };
              output-volume = {
                type = "volume";
                device = "output";
                peek = lib.mkDefault true;
              };
              brightness.peek = lib.mkDefault true;
              tray-volume-spacer = {
                type = "spacer";
                length = lib.mkDefault 20;
              };
              tray.drawer = lib.mkDefault false;
              network.peek = lib.mkDefault true;
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

            brightness.enable_ddcutil = lib.mkDefault true;

            bluetooth.connection_notifications = lib.mkDefault true;

            calendar = {
              enabled = lib.mkDefault true;
              refresh_minutes = lib.mkDefault 15;
            };

            lockscreen = {
              allow_empty_password = lib.mkDefault true;
              blurred_desktop = lib.mkDefault true;
              tint_intensity = lib.mkDefault 0.50;
              dnd = lib.mkDefault true;
            };

            # widgets and login boxes are placed per output in absolute
            # coordinates, so each machine declares its own in machines/<machine>/home
            lockscreen_widgets.enabled = lib.mkDefault true;

            location.auto_locate = lib.mkDefault true;

            wallpaper.directory = lib.mkDefault "${config.home.homeDirectory}/Pictures/Wallpapers";

            weather = {
              enabled = lib.mkDefault true;
            };

            notification = {
              position = lib.mkDefault "top_right";
              background_opacity = lib.mkDefault 0.80;
              follow_focused_output = lib.mkDefault true;
            };
          };
        };

        # fosskar/displays saves ad-hoc kanshi profiles into this mutable file:
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
