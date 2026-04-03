{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ];

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

      programs.noctalia-shell = {
        enable = true;
        systemd.enable = true;

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
                  id = "Battery";
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

          osd.location = "right";

          sessionMenu = {
            countdownDuration = 1000;
            largeButtonsLayout = "grid";
          };
        };
      };
    }
  );
}
