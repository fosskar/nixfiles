{ pkgs, ... }:
{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4";
      focus = {
        followMouse = false;
        mouseWarping = false;
      };
      menu = "rofi -show drun -show-icons";
      workspaceAutoBackAndForth = true;
      defaultWorkspace = "workspace number 1";

      colors = {
        focused = {
          background = "#222222";
          border = "#00F4A2";
          childBorder = "#00F4A2";
          indicator = "#000000";
          text = "#ffffff";
        };
        focusedInactive = {
          background = "#5f676a";
          border = "#333333";
          childBorder = "#5f676a";
          indicator = "#484e50";
          text = "#ffffff";
        };
        unfocused = {
          background = "#222222";
          border = "#333333";
          childBorder = "#222222";
          indicator = "#292d2e";
          text = "#888888";
        };
        urgent = {
          background = "#900000";
          border = "#2f343a";
          childBorder = "#900000";
          indicator = "#900000";
          text = "#ffffff";
        };
        placeholder = {
          background = "#0c0c0c";
          border = "#000000";
          childBorder = "#0c0c0c";
          indicator = "#000000";
          text = "#ffffff";
        };
      };

      startup = [
        { command = "--no-startup-id keepassxc"; }
        { command = "--no-startup-id nm-applet"; }
        { command = "--no-startup-id blueman-applet"; }
        { command = "--no-startup-id dex --autostart --environment i3"; }
      ];

      window = {
        titlebar = false;
        border = 1;
        hideEdgeBorders = "smart";
      };

      keybindings =
        let
          mod = "Mod4";
        in
        {
          "${mod}+t" = "exec wezterm";
          "${mod}+r" = "exec kitty";
          "${mod}+w" = "exec firefox";
          "${mod}+z" = "exec zoom";
          "${mod}+s" = "exec slack";
          "${mod}+o" = "exec obsidian";
          "Print" = "exec flameshot";
          "${mod}+Shift+e" = "exec nautilus";
          "${mod}+e" = "exec wezterm -e yazi";
          "${mod}+c" = "exec codium";
          "${mod}+Shift+q" = "kill";
          "${mod}+j" = "focus left";
          "${mod}+k" = "focus down";
          #"${mod}+l" = "focus up"; #FIXME
          "${mod}+semicolon" = "focus right";
          "${mod}+Left" = "focus left";
          "${mod}+Down" = "focus down";
          "${mod}+Up" = "focus up";
          "${mod}+Right" = "focus right";
          "${mod}+Shift+j" = "move left";
          "${mod}+Shift+k" = "move down";
          "${mod}+Shift+l" = "move up";
          "${mod}+Shift+semicolon" = "move right";
          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Right" = "move right";
          "${mod}+Ctrl+Left" = "resize grow left";
          "${mod}+Ctrl+Down" = "resize grow down";
          "${mod}+Ctrl+Up" = "resize grow up";
          "${mod}+Ctrl+Right" = "resize grow right";
          "${mod}+h" = "layout toggle split";
          "${mod}+Shift+v" = "split v";
          "${mod}+f" = "fullscreen";
          "${mod}+Shift+s" = "layout stacking";
          "${mod}+Shift+t" = "layout tabbed";
          "${mod}+Shift+g" = "sticky toggle";
          "${mod}+v" = "floating toggle";
          "${mod}+Ctrl+greater" = "move workspace to output right";
          "${mod}+Ctrl+less" = "move workspace to output left";
          "${mod}+space" = "exec rofi -show drun -show-icons";
          "${mod}+1" = "workspace 1";
          "${mod}+2" = "workspace 2";
          "${mod}+3" = "workspace 3";
          "${mod}+4" = "workspace 4";
          "${mod}+5" = "workspace 5";
          "${mod}+6" = "workspace 6";
          "${mod}+7" = "workspace 7";
          "${mod}+8" = "workspace 8";
          "${mod}+9" = "workspace 9";
          "${mod}+0" = "workspace 10";
          "${mod}+Shift+1" = "move container to workspace 1";
          "${mod}+Shift+2" = "move container to workspace 2";
          "${mod}+Shift+3" = "move container to workspace 3";
          "${mod}+Shift+4" = "move container to workspace 4";
          "${mod}+Shift+5" = "move container to workspace 5";
          "${mod}+Shift+6" = "move container to workspace 6";
          "${mod}+Shift+7" = "move container to workspace 7";
          "${mod}+Shift+8" = "move container to workspace 8";
          "${mod}+Shift+9" = "move container to workspace 9";
          "${mod}+Shift+0" = "move container to workspace 10";
          "${mod}+Shift+c" = "reload";
          "${mod}+Shift+r" = "restart";
          "${mod}+Shift+o" = "exec 'i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'";
          "${mod}+l" = "exec i3lock -c 000000";
          "XF86AudioMute" = "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $refresh_i3status";
          "XF86AudioPlay" = "exec --no-startup-id 'playerctl --player=spotify,firefox play-pause'";
          "XF86AudioPrev" = "exec --no-startup-id 'playerctl --player=spotify,firefox previous'";
          "XF86AudioNext" = "exec --no-startup-id 'playerctl --player=spotify,firefox next'";
        };
      bars = [
        {
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-custom.toml";
          position = "top";
          workspaceButtons = true;
          trayOutput = "primary";
          colors = {
            background = "#222222";
            statusline = "#eeeeee";
            separator = "#ffffff";
            focusedWorkspace = {
              background = "#00F4A2";
              border = "#00F4A2";
              text = "#222222";
            };
            activeWorkspace = {
              background = "#333333";
              border = "#5f676a";
              text = "#ffffff";
            };
            inactiveWorkspace = {
              background = "#333333";
              border = "#222222";
              text = "#888888";
            };
            urgentWorkspace = {
              background = "#E34234";
              border = "#E34234";
              text = "#222222";
            };
          };
        }
      ];
      gaps = {
        inner = 4;
        outer = 2;
        smartGaps = true;
        smartBorders = "on";
      };

      floating = {
        titlebar = false;
        border = 1;
        criteria = [
          { class = "KeePassXC"; }
          { class = "zoom"; }
          { class = "Zoom Meeting"; }
          { class = "Slack"; }
        ];
      };

      terminal = "${pkgs.kitty}/bin/kitty";

      fonts = {
        names = [ "Inter Variable" ];
        size = 16.0;
      };
    };
  };
}
