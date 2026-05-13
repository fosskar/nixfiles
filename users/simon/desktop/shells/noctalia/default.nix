{
  config,
  lib,
  inputs,
  mylib,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ] ++ mylib.scanPaths ./. { };

  config =
    let
      t = config.theme;
    in
    {
      xdg.configFile."noctalia/colorschemes/grey-teal/grey-teal.json".text = builtins.toJSON {
        dark = {
          mPrimary = t.dark.accent.primary;
          mOnPrimary = t.dark.bg.base;
          mSecondary = t.dark.semantic.warning;
          mOnSecondary = t.dark.bg.base;
          mTertiary = t.ansi.normal.blue;
          mOnTertiary = t.dark.bg.base;
          mError = t.dark.semantic.error;
          mOnError = t.dark.bg.base;
          mSurface = t.dark.bg.base;
          mOnSurface = t.dark.fg.base;
          mHover = t.dark.accent.primary;
          mOnHover = t.dark.bg.base;
          mSurfaceVariant = t.dark.bg.surface;
          mOnSurfaceVariant = t.dark.fg.muted;
          mOutline = t.dark.fg.dim;
          mShadow = t.dark.bg.base;
        };
        light = {
          mPrimary = t.light.accent.primary;
          mOnPrimary = t.light.bg.base;
          mSecondary = t.light.semantic.warning;
          mOnSecondary = t.light.bg.base;
          mTertiary = t.ansi.normal.blue;
          mOnTertiary = t.light.bg.base;
          mError = t.light.semantic.error;
          mOnError = t.light.bg.base;
          mSurface = t.light.bg.base;
          mOnSurface = t.light.fg.base;
          mHover = t.light.accent.primary;
          mOnHover = t.light.bg.base;
          mSurfaceVariant = t.light.bg.surface;
          mOnSurfaceVariant = t.light.fg.muted;
          mOutline = t.light.fg.dim;
          mShadow = t.light.bg.overlay;
        };
      };

      # upstream home-module deprecated its systemd integration and its
      # warning emission is broken (sets `warnings` key on systemd.user.services,
      # causing eval failure). inline the original unit 1:1 instead of
      # enabling cfg.systemd.enable.
      systemd.user.services.noctalia-shell =
        let
          cfg = config.programs.noctalia-shell;
        in
        {
          Unit = {
            Description = "Noctalia Shell - Wayland desktop shell";
            Documentation = "https://docs.noctalia.dev";
            PartOf = [ config.wayland.systemd.target ];
            After = [ config.wayland.systemd.target ];
            X-Restart-Triggers =
              lib.optional (cfg.settings != { }) "${config.xdg.configFile."noctalia/settings.json".source}"
              ++ lib.optional (cfg.colors != { }) "${config.xdg.configFile."noctalia/colors.json".source}"
              ++ lib.optional (cfg.plugins != { }) "${config.xdg.configFile."noctalia/plugins.json".source}"
              ++ lib.optional (
                cfg.user-templates != { }
              ) "${config.xdg.configFile."noctalia/user-templates.toml".source}"
              ++ lib.mapAttrsToList (
                name: _: "${config.xdg.configFile."noctalia/plugins/${name}/settings.json".source}"
              ) cfg.pluginSettings;
          };
          Service = {
            ExecStart = lib.getExe cfg.package;
            Restart = "on-failure";
          };
          Install.WantedBy = [ config.wayland.systemd.target ];
        };

      programs.noctalia-shell = {
        enable = true;

        settings = {
          colorSchemes = {
            predefinedScheme = "grey-teal";
            darkMode = true;
          };
          appLauncher = {
            terminalCommand = "ghostty -e";
          };

          templates = {
            enableUserTheming = true;
            activeTemplates = [
              {
                id = "btop";
                enabled = true;
              }
              {
                id = "gtk";
                enabled = true;
              }
              {
                id = "yazi";
                enabled = true;
              }
              {
                id = "zathura";
                enabled = true;
              }
              {
                id = "zed";
                enabled = true;
              }
              {
                id = "zen-browser";
                enabled = true;
              }
            ];
          };

          bar = {
            backgroundOpacity = 1;
            showCapsule = false;
            widgets = {
              center = [
                {
                  id = "Clock";
                  formatHorizontal = "HH:mm\\ndd.MM.yy";
                }
                {
                  id = "plugin:privacy-indicator";
                  hideInactive = true;
                  removeMargins = true;
                  activeColor = "error";
                }
              ];
              left = [
                {
                  id = "ControlCenter";
                  useDistroLogo = true;
                }
                {
                  id = "Workspace";
                  hideUnoccupied = true;
                  labelMode = "Name";
                }
                {
                  id = "SystemMonitor";
                }
                {
                  id = "plugin:c4d277:display-config";
                }
                {
                  id = "plugin:mirror-mirror";
                }
              ];
              right = [
                {
                  id = "Tray";
                  drawerEnabled = false;
                  hidePassive = true;
                }
                {
                  id = "Microphone";
                }
                {
                  id = "Volume";
                }
                {
                  id = "plugin:netbird";
                }
                {
                  id = "VPN";
                }
                {
                  id = "Network";
                }
                {
                  id = "Bluetooth";
                }
                {
                  id = "Battery";
                }
                {
                  id = "NoctaliaPerformance";
                }
                {
                  id = "PowerProfile";
                }
                {
                  id = "KeepAwake";
                }
                {
                  id = "NotificationHistory";
                }
                {
                  id = "SessionMenu";
                }
              ];
            };
          };

          dock = {
            enabled = false;
          };

          idle = {
            enabled = true;
            screenOffTimeout = 300;
            lockTimeout = 1800;
            suspendTimeout = 3600;
          };

          general = {
            showScreenCorners = true;
            forceBlackScreenCorners = true;
            compactLockScreen = true;
          };

          location = {
            name = "Hamburg";
          };

          notifications = {
            density = "compact";
          };

          osd.location = "right";

          wallpaper = {
            enabled = true;
            useWallhaven = true;
            automationEnabled = false;
          };

          sessionMenu = {
            countdownDuration = 1000;
            largeButtonsLayout = "grid";
          };
        };
      };
    };
}
