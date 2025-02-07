{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.module.desktop.wayland.bar;
in
{

  imports = [
    inputs.hyprpanel.homeManagerModules.hyprpanel
    ./theme.nix
  ];

  config = mkIf (cfg == "hyprpanel") {

    home.packages = with pkgs; [
      hyprpanel
    ];

    programs.hyprpanel = {
      enable = true;
      config.enable = true;
      overlay.enable = true;
      hyprland.enable = false;
      overwrite.enable = true;
      theme = "";
      layout = {
        "bar.layouts" = {
          "*" = {
            left = [
              "dashboard"
              "workspaces"
              "storage"
              "ram"
              "cpu"
              "cputemp"
            ];
            middle = [
              "clock"
              "media"
            ];
            right = [
              "systray"
              "volume"
              "network"
              "bluetooth"
              "notifications"
              "hypridle"
              "power"
            ];
          };
        };
      };
      settings = {
        bar = {
          autoHide = "never";
          battery = {
            hideLabelWhenFull = false;
            label = true;
            middleClick = "";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
          };
          bluetooth = {
            label = false;
            middleClick = "";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
          };
          clock = {
            format = "%H:%M ";
            icon = "󰸗";
            middleClick = "";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
            showIcon = false;
            showTime = true;
          };
          customModules = {
            cava = {
              showIcon = true;
              icon = "";
              spaceCharacter = " ";
              barCharacters = [
                "▁"
                "▂"
                "▃"
                "▄"
                "▅"
                "▆"
                "▇"
                "█"
              ];
              showActiveOnly = false;
              bars = 10;
              channels = 2;
              framerate = 60;
              samplerate = 44100;
              autoSensitivity = true;
              lowCutoff = 50;
              highCutoff = 10000;
              noiseReduction = 0.77;
              stereo = false;
              leftClick = "";
              rightClick = "";
              middleClick = "";
              scrollUp = "";
              scrollDown = "";
            };
            cpu = {
              icon = "";
              label = true;
              leftClick = "";
              middleClick = "";
              pollingInterval = 2000;
              rightClick = "";
              round = true;
              scrollDown = "";
              scrollUp = "";
            };
            cpuTemp = {
              icon = "";
              label = true;
              leftClick = "";
              middleClick = "";
              pollingInterval = 2000;
              rightClick = "";
              round = true;
              scrollDown = "";
              scrollUp = "";
              sensor = "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon3/temp1_input";
              showUnit = true;
              unit = "metric";
            };
            hypridle = {
              label = false;
              middleClick = "";
              offIcon = "";
              offLabel = "Off";
              onIcon = "";
              onLabel = "On";
              pollingInterval = 2000;
              rightClick = "";
              scrollDown = "";
              scrollUp = "";
            };
            hyprsunset = {
              label = true;
              middleClick = "";
              offIcon = "󰛨";
              offLabel = "Off";
              onIcon = "󱩌";
              onLabel = "On";
              pollingInterval = 2000;
              rightClick = "";
              scrollDown = "";
              scrollUp = "";
              temperature = "6000k";
            };
            kbLayout = {
              icon = "󰌌";
              label = true;
              labelType = "code";
              leftClick = "";
              middleClick = "";
              rightClick = "";
              scrollDown = "";
              scrollUp = "";
            };
            netstat = {
              dynamicIcon = false;
              icon = "󰖟";
              label = true;
              labelType = "full";
              leftClick = "";
              middleClick = "";
              networkInLabel = "↓";
              networkInterface = "";
              networkOutLabel = "↑";
              pollingInterval = 2000;
              rateUnit = "auto";
              rightClick = "";
              round = true;
            };
            power = {
              icon = "";
              leftClick = "menu:powerdropdown";
              middleClick = "";
              rightClick = "";
              scrollDown = "";
              scrollUp = "";
              showLabel = true;
            };
            ram = {
              icon = "";
              label = true;
              labelType = "percentage";
              leftClick = "";
              middleClick = "";
              pollingInterval = 2000;
              rightClick = "";
              round = true;
            };
            scrollSpeed = 5;
            storage = {
              icon = "󰋊";
              label = true;
              labelType = "percentage";
              leftClick = "";
              middleClick = "";
              pollingInterval = 2000;
              rightClick = "";
              round = false;
            };
            submap = {
              disabledIcon = "󰌌";
              disabledText = "Submap off";
              enabledIcon = "󰌐";
              enabledText = "Submap On";
              label = true;
              leftClick = "";
              middleClick = "";
              rightClick = "";
              scrollDown = "";
              scrollUp = "";
              showSubmapName = true;
            };
            updates = {
              autoHide = false;
              icon = {
                pending = "󰏗";
                updated = "󰏖";
              };
              label = true;
              leftClick = "";
              middleClick = "";
              padZero = true;
              pollingInterval = 1440000;
              rightClick = "";
              scrollDown = "";
              scrollUp = "";
              updateCommand = "";
            };
            weather = {
              label = true;
              leftClick = "";
              middleClick = "";
              rightClick = "";
              scrollDown = "";
              scrollUp = "";
              unit = "metric";
            };
          };
          launcher = {
            autoDetectIcon = true;
            icon = "";
            middleClick = "";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
          };
          media = {
            format = "{name}";
            middleClick = "";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
            show_active_only = true;
            show_label = true;
            truncation = true;
            truncation_size = 30;
          };
          network = {
            label = false;
            middleClick = "";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
            showWifiInfo = true;
            truncation = true;
            truncation_size = 7;
          };
          notifications = {
            hideCountWhenZero = true;
            middleClick = "";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
            show_total = true;
          };
          scrollSpeed = 5;
          volume = {
            label = true;
            middleClick = "pavucontrol";
            rightClick = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            scrollDown = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0";
            scrollUp = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- --limit 0.0";
          };
          windowtitle = {
            class_name = true;
            custom_title = true;
            icon = true;
            label = false;
            leftClick = "";
            middleClick = "";
            rightClick = "";
            scrollDown = "";
            scrollUp = "";
            truncation = false;
            truncation_size = 50;
          };
          workspaces = {
            applicationIconEmptyWorkspace = "";
            applicationIconFallback = "󰣆";
            applicationIconOncePerWorkspace = true;
            icons = {
              active = "";
              available = "";
              occupied = "";

            };
            ignored = "";
            monitorSpecific = true;
            numbered_active_indicator = "underline";
            reverse_scroll = true;
            scroll_speed = 5;
            showAllActive = true;
            showApplicationIcons = false;
            showWsIcons = false;
            show_icons = false;
            show_numbered = false;
            spacing = 1.0;
            workspaceMask = false;
            workspaces = 0;
          };
        };
        dummy = true;
        hyprpanel = {
          restartAgs = true;
        };
        menus = {
          clock = {
            time = {
              hideSeconds = false;
              military = true;
            };
            weather = {
              enabled = false;
              interval = 60000;
              key = "";
              location = "";
              unit = "metric";
            };
          };
          dashboard = {
            controls.enabled = true;
            directories = {
              enabled = true;
              left = {
                directory1 = {
                  command = "wezterm -e yazi ~";
                  label = "󱂵  home";
                };
                directory2 = {
                  command = "wezterm -e yazi ~/screenshots";
                  label = "󰉏  screenshots";
                };
                directory3 = {
                  command = "wezterm -e yazi ~/.config";
                  label = "󱋣  config";
                };
              };
              right = {
                directory1 = {
                  command = "wezterm -e yazi ~/downloads";
                  label = "󰉍  downloads";
                };
                directory2 = {
                  command = "wezterm -e yazi ~/code";
                  label = "󰉌  code";
                };
                directory3 = {
                  command = "wezterm -e yazi /";
                  label = "󰷌  /";
                };
              };
            };
            powermenu = {
              avatar = {
                image = "$HOME/downloads/unnamed.png";
                name = "system";
              };
              confirmation = true;
              logout = "hyprctl dispatch exit";
              reboot = "systemctl reboot";
              shutdown = "systemctl poweroff";
              sleep = "systemctl suspend";
            };
            shortcuts = {
              enabled = true;
              left = {
                shortcut1 = {
                  command = "";
                  icon = "";
                  tooltip = "";
                };
                shortcut2 = {
                  command = "spotify";
                  icon = "";
                  tooltip = "Spotify";
                };
                shortcut3 = {
                  command = "webcord";
                  icon = "";
                  tooltip = "Discord";
                };
                shortcut4 = {
                  command = "anyrun";
                  icon = "";
                  tooltip = "Search Apps";
                };
              };
              right = {
                shortcut1 = {
                  command = "sleep 0.5 && hyprpicker -a";
                  icon = "";
                  tooltip = "Color Picker";
                };
                shortcut3 = {
                  command = "hyprshot -m region -o ~/pictures/screenshots -- imv";
                  icon = "󰄀";
                  tooltip = "Screenshot";
                };
              };
            };
            stats = {
              enabled = true;
              enable_gpu = false;
              interval = 2000;
            };
          };
          media = {
            displayTime = false;
            displayTimeTooltip = false;
            hideAlbum = false;
            hideAuthor = false;
            noMediaText = "";
          };
          power = {
            confirmation = true;
            logout = "hyprctl dispatch exit";
            lowBatteryNotification = false;
            lowBatteryNotificationText = "Your battery is running low ($POWER_LEVEL %).\\n\\nPlease plug in your charger.";
            lowBatteryNotificationTitle = "Warning: Low battery";
            lowBatteryThreshold = 20;
            reboot = "systemctl reboot";
            showLabel = true;
            shutdown = "systemctl poweroff";
            sleep = "systemctl suspend";
          };
          transition = "crossfade";
          transitionTime = 500;
          volume.raiseMaximumVolume = false;
        };
        notifications = {
          active_monitor = true;
          cache_actions = true;
          clearDelay = 100;
          displayedTotal = 10;
          monitor = 0;
          position = "top right";
          showActionsOnHover = false;
          timeout = 7000;
        };
        scalingPriority = "gdk";
        tear = true;
        terminal = "wezterm";
        theme = {
          bar = {
            border = {
              location = "none";
              width = "0.15em";
            };
            border_radius = "0.6em";
            buttons = {
              background_hover_opacity = 80;
              background_opacity = 100;
              battery = {
                enableBorder = false;
                spacing = "0.5em";
              };
              bluetooth = {
                enableBorder = false;
                spacing = "0.5em";
              };
              borderSize = "0.01em";
              clock = {
                enableBorder = false;
                spacing = "0em";
              };
              dashboard = {
                enableBorder = false;
                spacing = "0.5em";
              };
              enableBorders = false;
              innerRadiusMultiplier = "0.4";
              media = {
                enableBorder = false;
                spacing = "0.3em";
              };
              modules = {
                cpu = {
                  enableBorder = false;
                  spacing = "0.5em";
                };
                cpuTemp = {
                  enableBorder = false;
                  spacing = "0.5em";
                };
                hypridle = {
                  enableBorder = false;
                  spacing = "0.45em";
                };
                hyprsunset = {
                  enableBorder = false;
                  spacing = "0.45em";
                };
                kbLayout = {
                  enableBorder = false;
                  spacing = "0.45em";
                };
                netstat = {
                  enableBorder = false;
                  spacing = "0.45em";
                };
                power = {
                  enableBorder = false;
                  spacing = "0.45em";
                };
                ram = {
                  enableBorder = false;
                  spacing = "0.45em";
                };
                storage = {
                  enableBorder = false;
                  spacing = "0.45em";
                };
                submap = {
                  enableBorder = false;
                  spacing = "0.45em";
                };
                updates = {
                  enableBorder = false;
                  spacing = "0.45em";
                };
                weather = {
                  enableBorder = false;
                  spacing = "0.45em";
                };
              };
              monochrome = false;
              network = {
                enableBorder = false;
                spacing = "0.5em";
              };
              notifications = {
                enableBorder = false;
                spacing = "0.5em";
              };
              opacity = 100;
              padding_x = "0.6rem";
              padding_y = "0.0rem";
              radius = "0.6em";
              spacing = "0.2em";
              style = "default";
              systray = {
                enableBorder = false;
                spacing = "0.5em";
              };
              volume = {
                enableBorder = false;
                spacing = "0.5em";
              };
              windowtitle = {
                enableBorder = false;
                spacing = "0.5em";
              };
              workspaces = {
                enableBorder = false;
                fontSize = "1.2em";
                numbered_active_highlight_border = "0.2em";
                numbered_active_highlight_padding = "0.2em";
                numbered_inactive_padding = "0.2em";
                pill = {
                  active_width = "12em";
                  height = "4em";
                  radius = "1.9rem * 0.6";
                  width = "4em";
                };
                smartHighlight = true;
                spacing = "0.5em";
              };
              y_margins = "0.2em";
            };
            dropdownGap = "2.2em";
            floating = false;
            label_spacing = "0.5em";
            layer = "top";
            location = "top";
            margin_bottom = "0.5em";
            margin_sides = "0.5em";
            margin_top = "0.5em";
            menus = {
              border = {
                radius = "0.8em";
                size = "0.13em";
              };
              buttons.radius = "0.4em";
              card_radius = "0.4em";
              menu = {
                battery.scaling = 100;
                bluetooth.scaling = 90;
                clock.scaling = 85;
                dashboard = {
                  confirmation_scaling = 90;
                  profile.radius = "1.0em";
                  profile.size = "8.0em";
                  scaling = 100;
                };
                media = {
                  card.tint = 80;
                  scaling = 90;
                };
                network.scaling = 90;
                notifications = {
                  height = "58em";
                  pager.show = true;
                  scaling = 85;
                  scrollbar = {
                    radius = "0.2em";
                    width = "0.35em";
                  };
                };
                power = {
                  radius = "0.4em";
                  scaling = 90;
                };
                volume.scaling = 90;
              };
              monochrome = false;
              opacity = 100;
              popover = {
                radius = "0.4em";
                scaling = 100;
              };
              progressbar.radius = "0.3rem";
              scroller = {
                radius = "0.7em";
                width = "0.25em";
              };
              slider = {
                progress_radius = "0.3rem";
                slider_radius = "0.3rem";
              };
              switch = {
                radius = "0.3em";
                slider_radius = "0.3em";
              };
              tooltip.radius = "0.3em";
            };
            opacity = 100;
            outer_spacing = "0.0em";
            scaling = 90;
            transparent = false;
          };
          font = {
            name = "Inter Medium";
            size = "1.2rem";
            weight = 600;
          };
          matugen = false;
          matugen_settings = {
            contrast = 0;
            mode = "dark";
            scheme_type = "tonal-spot";
            variation = "standard_1";
          };
          notification = {
            border_radius = "0.6em";
            opacity = 100;
            scaling = 90;
          };
          osd = {
            active_monitor = true;
            duration = 2500;
            enable = true;
            location = "right";
            margins = "0px 5px 0px 0px";
            monitor = 0;
            muted_zero = true;
            opacity = 100;
            orientation = "vertical";
            radius = "0.4em";
            border.size = "0em";
            scaling = 90;
          };
          tooltip.scaling = 90;
        };
        wallpaper = {
          enable = false;
          image = "";
          pywal = false;
        };
      };
    };
  };
}
