{
  config,
  lib,
  inputs,
  mylib,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ] ++ mylib.scanPaths ./. { };

  config = lib.mkIf (config.nixfiles.quickshell == "noctalia") (
    let
      t = config.theme;
    in
    {
      #xdg.configFile."noctalia/pam/password.conf".text = ''
      #  auth sufficient pam_fprintd.so max-tries=1
      #  auth required pam_unix.so
      #'';

      xdg.configFile."noctalia/colorschemes/grey-teal/grey-teal.json".text = builtins.toJSON {
        dark = {
          mPrimary = t.primary;
          mOnPrimary = t.bg;
          mSecondary = t.secondary;
          mOnSecondary = t.bg;
          mTertiary = t.info;
          mOnTertiary = t.bg;
          mError = t.error;
          mOnError = t.bg;
          mSurface = t.bg;
          mOnSurface = t.fg;
          mHover = t.primary;
          mOnHover = t.bg;
          mSurfaceVariant = t.bgLight;
          mOnSurfaceVariant = t.fgMuted;
          mOutline = t.fgDim;
          mShadow = t.bg;
        };
        light = {
          mPrimary = t.light.primary;
          mOnPrimary = t.light.bg;
          mSecondary = t.secondary;
          mOnSecondary = t.light.bg;
          mTertiary = t.info;
          mOnTertiary = t.light.bg;
          mError = t.light.error;
          mOnError = t.light.bg;
          mSurface = t.light.bg;
          mOnSurface = t.light.fg;
          mHover = t.light.primary;
          mOnHover = t.light.bg;
          mSurfaceVariant = t.light.bgDark;
          mOnSurfaceVariant = t.light.fgMuted;
          mOutline = t.light.outline;
          mShadow = t.light.bgDarkest;
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
                  id = "plugin:model-usage";
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
    }
  );
}
