{ inputs, ... }:
{
  flake.modules.homeManager.noctalia-v5 =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.noctalia-v5;
      toml = pkgs.formats.toml { };
      inherit (config) theme;

      lockSecrets = pkgs.writeShellScript "lock-secrets" ''
        ${pkgs.libsecret}/bin/secret-tool lock --collection=kdewallet 2>/dev/null || true
      '';

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
      options.programs.noctalia-v5 = {
        enable = lib.mkEnableOption "Noctalia v5";

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.noctalia-v5.packages.${pkgs.stdenv.hostPlatform.system}.default;
          defaultText = lib.literalExpression "inputs.noctalia-v5.packages.${pkgs.stdenv.hostPlatform.system}.default";
          description = "Noctalia v5 package.";
        };

        settings = lib.mkOption {
          inherit (toml) type;
          default = { };
          description = "Noctalia v5 TOML settings written to ~/.config/noctalia/config.toml.";
        };
      };

      config = lib.mkMerge [
        {
          programs.noctalia-v5 = {
            enable = lib.mkDefault true;

            settings = {
              shell = {
                font_family = theme.fonts.sans;
                time_format = "{:%H:%M}";
                date_format = "%d.%m.%y";
                telemetry_enabled = false;
                polkit_agent = false;
                show_location = true;
                screen_corners.enabled = true;
                panel = {
                  background_blur = true;
                  transparency_mode = "soft";
                  attach_control_center = true;
                  attach_wallpaper = true;
                };
              };

              osd.position = "top_right";

              theme = {
                mode = "dark";
                source = "custom";
                custom_palette = "grey-teal";
                templates = {
                  enable_builtin_templates = true;
                  enable_community_templates = false;
                  builtin_ids = [
                    "btop"
                    "gtk3"
                    "gtk4"
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
                  start = [
                    "control-center"
                    "workspaces"
                    "cpu"
                  ];
                  center = [ "clock" ];
                  end = [
                    "tray"
                    "input-volume"
                    "volume"
                    "network"
                    "bluetooth"
                    "battery"
                    "power_profiles"
                    "caffeine"
                    "notifications"
                    "session"
                  ];
                };
              };

              widget = {
                clock.format = "{:%H:%M}\\n{:%d.%m.%y}";
                workspaces = {
                  display = "name";
                  hide_when_empty = true;
                };
                cpu = {
                  type = "sysmon";
                  stat = "cpu_usage";
                };
                input-volume = {
                  type = "volume";
                  device = "input";
                };
                tray.drawer = false;
                notifications.hide_when_no_unread = false;
              };

              dock.enabled = false;
              desktop_widgets.enabled = false;

              idle.behavior = {
                screen-off = {
                  enabled = true;
                  timeout = 300;
                  command = "noctalia:dpms-off";
                  resume_command = "noctalia:dpms-on";
                };
                lock = {
                  enabled = true;
                  timeout = 1800;
                  command = "noctalia:screen-lock";
                };
              };

              system.monitor.enabled = true;

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
                started = "noctalia msg screen-lock";
                session_locked = toString lockSecrets;
                session_unlocked = "kwallet-tpm-unlock $HOME/.config/kwallet-tpm/password.cred";
              };
            };
          };
        }

        (lib.mkIf cfg.enable {
          xdg.configFile = {
            "noctalia/00-nix.toml".source = toml.generate "noctalia-v5-config.toml" cfg.settings;
            "noctalia/palettes/grey-teal.json".text = builtins.toJSON palette;
          };

          systemd.user.services.noctalia-v5 = {
            Unit = {
              Description = "Noctalia v5 Wayland shell";
              Documentation = "https://docs.noctalia.dev/v5/";
              PartOf = [ config.wayland.systemd.target ];
              After = [ config.wayland.systemd.target ];
              X-Restart-Triggers = [ config.xdg.configFile."noctalia/00-nix.toml".source ];
            };
            Service = {
              ExecStart = lib.getExe cfg.package;
              Restart = "on-failure";
            };
            Install.WantedBy = [ config.wayland.systemd.target ];
          };
        })
      ];
    };
}
