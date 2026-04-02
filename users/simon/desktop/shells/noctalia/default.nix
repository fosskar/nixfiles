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
      xdg.configFile."noctalia/pam/password.conf".text = ''
        auth sufficient pam_fprintd.so max-tries=1
        auth required pam_unix.so
      '';

      programs.noctalia-shell = {
        enable = true;
        systemd.enable = true;
        colors = {
          mPrimary = t.primary;
          mSecondary = t.secondary;
          mTertiary = t.info;
          mError = t.error;
          mSurface = t.bg;
          mSurfaceVariant = t.bgLight;
          mOnPrimary = "#FFFFFF";
          mOnSecondary = "#FFFFFF";
          mOnTertiary = "#FFFFFF";
          mOnError = "#FFFFFF";
          mOnSurface = t.fg;
          mOnSurfaceVariant = t.fgMuted;
          mOutline = t.fgDim;
          mShadow = "#000000";
        };
        # plugins managed via noctalia GUI
        settings = {
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
          };

          templates.activeTemplates = [
            {
              id = "gtk";
              enabled = true;
            }
            {
              id = "niri";
              enabled = true;
            }
            {
              id = "yazi";
              enabled = true;
            }
          ];

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
