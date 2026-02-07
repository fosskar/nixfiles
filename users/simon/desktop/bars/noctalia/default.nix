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
        appLauncher = {
          terminalCommand = "ghostty -e";
          iconMode = "tabler";
          sortByMostUsed = true;
          viewMode = "list";
        };

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
                id = "Network";
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
            ];
          };
        };

        colorSchemes = {
          # predefinedScheme = "Oxocarbon";
          matugenSchemeType = "scheme-neutral";
          useWallpaperColors = true;
        };

        controlCenter = {
          position = "top_center";
          cards = [
            {
              enabled = true;
              id = "profile-card";
            }
            {
              enabled = true;
              id = "shortcuts-card";
            }
            {
              enabled = true;
              id = "audio-card";
            }
            {
              enabled = false;
              id = "brightness-card";
            }
            {
              enabled = true;
              id = "weather-card";
            }
            {
              enabled = true;
              id = "media-sysmon-card";
            }
          ];
        };

        dock = {
          enabled = true;
          displayMode = "auto_hide";
          position = "bottom";
          onlySameOutput = true;
        };

        general = {
          showScreenCorners = true;
          forceBlackScreenCorners = true;
          animationSpeed = 2;
          compactLockScreen = true;
          enableShadows = false;
        };

        location = {
          name = "Hamburg";
          weatherEnabled = true;
          hideWeatherCityName = true;
          hideWeatherTimezone = true;
          showWeekNumberInCalendar = true;
        };

        notifications.sounds.volume = 0.1;

        osd.location = "right";

        sessionMenu = {
          countdownDuration = 1000;
          largeButtonsStyle = true;
          largeButtonsLayout = "grid";
        };

        templates = {
          ghostty = true;
          gtk = true;
          niri = true;
          qt = true;
          yazi = true;
          zed = true;
          zenBrowser = true;
        };

        ui = {
          fontDefault = config.font;
          fontFixed = config.monospaceFont;
          panelsAttachedToBar = true;
        };

        wallpaper = {
          enabled = true;
          directory = "/home/simon/pictures/wallpaper";
          fillMode = "crop";
          transitionType = "random";
          transitionDuration = 1500;
          overviewEnabled = true;
          setWallpaperOnAllMonitors = true;
        };
      };
    };
  };
}
