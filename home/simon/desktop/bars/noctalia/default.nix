{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.quickshell = {
    enable = true;
    package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  programs.noctalia-shell = {
    enable = true;
    settings = {
      appLauncher = {
        backgroundOpacity = 0.7;
        enableClipboardHistory = true;
        pinnedExecs = [ ];
        position = "center";
        sortByMostUsed = true;
        useApp2Unit = false;
      };

      audio = {
        cavaFrameRate = 30;
        mprisBlacklist = [ ];
        preferredPlayer = "mpv, spotify";
        visualizerType = "linear";
        volumeStep = 5;
      };

      bar = {
        backgroundOpacity = 0.8;
        floating = false;
        marginHorizontal = 0.25;
        marginVertical = 0.25;
        monitors = [ ];
        position = "top";
        showCapsule = true;
        widgets = {
          center = [
            {
              formatHorizontal = "HH:mm\ndd.MM.yy";
              formatVertical = "";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
          left = [
            {
              id = "Spacer";
              width = 20;
            }
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "name";
            }
            {
              id = "SystemMonitor";
              showCpuTemp = true;
              showCpuUsage = true;
              showDiskUsage = true;
              showMemoryAsPercent = true;
              showMemoryUsage = true;
              showNetworkStats = false;
            }
          ];
          right = [
            { id = "Tray"; }
            {
              id = "Spacer";
              width = 10;
            }
            {
              displayMode = "alwaysShow";
              id = "Microphone";
            }
            {
              displayMode = "alwaysShow";
              id = "Volume";
            }
            {
              id = "Spacer";
              width = 10;
            }
            { id = "WiFi"; }
            { id = "Bluetooth"; }
            {
              id = "Spacer";
              width = 10;
            }
            { id = "PowerProfile"; }
            { id = "KeepAwake"; }
            {
              id = "Spacer";
              width = 10;
            }
            {
              hideWhenZero = true;
              id = "NotificationHistory";
              showUnreadBadge = true;
            }
            {
              id = "Spacer";
              width = 20;
            }
            {
              #icon = "noctalia";
              id = "SidePanelToggle";
              useDistroLogo = true;
            }
          ];
        };
      };

      brightness = {
        brightnessStep = 5;
      };

      colorSchemes = {
        darkMode = true;
        predefinedScheme = "Monochrome";
        useWallpaperColors = false;
      };

      dock = {
        autoHide = false;
        backgroundOpacity = 0.85;
        exclusive = true;
        floatingRatio = 0.65;
        monitors = [ "HDMI-A-2" ];
      };

      general = {
        animationSpeed = 2;
        avatarImage = "/home/simon/pictures/ChatGPT Image Apr 7, 2025, 07_01_34 PM.png";
        dimDesktop = false;
        forceBlackScreenCorners = false;
        radiusRatio = 1;
        screenRadiusRatio = 0.5;
        showScreenCorners = true;
      };

      hooks = {
        darkModeChange = "";
        enabled = false;
        wallpaperChange = "";
      };

      location = {
        name = "Hamburg";
        showWeekNumberInCalendar = true;
        use12hourFormat = false;
        useFahrenheit = false;
      };

      matugen = {
        enableUserTemplates = false;
        foot = true;
        fuzzel = true;
        ghostty = true;
        gtk3 = true;
        gtk4 = true;
        kitty = true;
        pywalfox = false;
        qt5 = true;
        qt6 = true;
        vesktop = true;
      };

      network = {
        bluetoothEnabled = false;
        wifiEnabled = false;
      };

      nightLight = {
        autoSchedule = true;
        dayTemp = "6500";
        enabled = false;
        forced = false;
        manualSunrise = "06:30";
        manualSunset = "18:30";
        nightTemp = "4000";
      };

      notifications = {
        criticalUrgencyDuration = 15;
        doNotDisturb = false;
        lastSeenTs = 1758397164000;
        lowUrgencyDuration = 3;
        monitors = [ ];
        normalUrgencyDuration = 8;
      };

      screenRecorder = {
        audioCodec = "opus";
        audioSource = "default_output";
        colorRange = "limited";
        directory = "/home/simon/videos";
        frameRate = 60;
        quality = "very_high";
        showCursor = true;
        videoCodec = "h264";
        videoSource = "portal";
      };

      settingsVersion = 1;

      ui = {
        fontBillboard = "Inter";
        fontDefault = "Inter";
        fontFixed = "JetBrainsMono Nerd Font Mono";
        idleInhibitorEnabled = false;
      };

      wallpaper = {
        directory = "${inputs.wallpaper}";
        enableMultiMonitorDirectories = false;
        enabled = true;
        fillColor = "#000000";
        fillMode = "crop";
        monitors = [
          {
            directory = "${inputs.wallpaper}";
            name = "DP-1";
            wallpaper = "${inputs.wallpaper}/a_forest_with_moss_and_trees.jpg";
          }
          {
            directory = "${inputs.wallpaper}";
            name = "HDMI-A-2";
            wallpaper = "${inputs.wallpaper}/wallpaper/astronaut-high.jpg";
          }
        ];
        randomEnabled = false;
        randomIntervalSec = 300;
        setWallpaperOnAllMonitors = false;
        transitionDuration = 1500;
        transitionEdgeSmoothness = 0.05;
        transitionType = "random";
      };
    };
  };
  systemd.user.services.noctalia-shell = {
    Unit = {
      Description = "Noctalia Shell - Wayland desktop shell";
      Documentation = [ "https://github.com/noctalia-dev/noctalia-shell" ];
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 3;
    };

    Service = {
      ExecStart = "${
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      }/bin/noctalia-shell";
      Restart = "on-failure";
      RestartSec = 3;
      TimeoutStartSec = 10;
      TimeoutStopSec = 5;
      Environment = "PATH=${config.home.path}/bin";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
