{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ];

  config = lib.mkIf (config.nixfiles.quickshell == "noctalia") {
    xdg.configFile."noctalia/pam/password.conf".text = ''
      auth sufficient pam_fprintd.so max-tries=1
      auth required pam_unix.so
    '';

    programs.noctalia-shell = {
      enable = true;
      systemd.enable = true;
      settings = {
        appLauncher.terminalCommand = "ghostty -e";

        audio.preferredPlayer = "mpv, spotify";

        bar = {
          backgroundOpacity = 1;
          capsuleOpacity = 0.15;
          showCapsule = false;
          widgets = {
            center = [
              {
                id = "Clock";
                formatHorizontal = "HH:mm\\ndd.MM.yy";
                usePrimaryColor = true;
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
                labelMode = "none";
              }
              {
                id = "SystemMonitor";
                compactMode = true;
                showCpuTemp = true;
                showCpuUsage = true;
                showDiskUsage = true;
                showLoadAverage = true;
                showMemoryAsPercent = true;
                showMemoryUsage = true;
                showNetworkStats = true;
                useMonospaceFont = true;
              }
            ];
            right = [
              {
                id = "Tray";
                hidePassive = true;
                drawerEnabled = false;
              }
              {
                id = "Microphone";
                displayMode = "alwaysShow";
              }
              {
                id = "Volume";
                displayMode = "alwaysShow";
              }
              {
                id = "Battery";
                displayMode = "alwaysShow";
                hideIfNotDetected = true;
                warningThreshold = 20;
              }
              {
                id = "VPN";
                displayMode = "onhover";
              }
              {
                id = "WiFi";
                displayMode = "onhover";
              }
              {
                id = "Bluetooth";
                displayMode = "onhover";
              }
              { id = "PowerProfile"; }
              { id = "KeepAwake"; }
              {
                id = "NotificationHistory";
                showUnreadBadge = true;
              }
              {
                id = "SessionMenu";
                colorName = "error";
              }
              { id = "plugin:launcher-button"; }
            ];
          };
        };

        colorSchemes = {
          predefinedScheme = "Monochrome";
          matugenSchemeType = "scheme-monochrome";
        };

        controlCenter.position = "top_center";

        general = {
          showScreenCorners = true;
          animationSpeed = 2;
          compactLockScreen = true;
        };

        notifications.sounds.volume = 0.1;

        osd.location = "right";

        sessionMenu = {
          countdownDuration = 1000;
          largeButtonsStyle = true;
          largeButtonsLayout = "grid";
        };

        ui = {
          fontDefault = "Inter";
          fontFixed = "JetBrainsMono Nerd Font Mono";
        };
      };
    };
  };
}
