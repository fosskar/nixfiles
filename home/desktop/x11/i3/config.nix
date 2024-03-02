{
  pkgs,
  home-manager,
  config,
  ...
}: {
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4";
      focus.followMouse = false;
      focus.mouseWarping = false;
      menu = "rofi -show drun";
      workspaceAutoBackAndForth = true;
      defaultWorkspace = "workspace number 1";

      startup = [
        {
          command = "xrandr --output DP-1 --mode 3440x1440 --rate 165";
        }
        {
          command = "easyeffects --gapplication-service";
        }
        {
          command = "steam -silent";
        }
      ];

      window = {
        titlebar = false;
        border = 2;
        hideEdgeBorders = "smart";
      };

      keybindings = let
        mod = "Mod4";
      in {
        "${mod}+t" = "exec kitty";
        "${mod}+w" = "exec firefox";
        "${mod}+e" = "exec thunar";
        "${mod}+c" = "exec code";
        "${mod}+Shift+q" = "kill";

        "${mod}+j" = "focus left";
        "${mod}+k" = "focus down";
        "${mod}+l" = "focus up";
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
        "${mod}+h" = "split h";
        "${mod}+v" = "split v";
        "${mod}+f" = "fullscreen";
        "${mod}+Shift+s" = "layout stacking";
        "${mod}+Shift+t" = "layout tabbed";
        "${mod}+Shift+g" = "sticky toggle";
        "${mod}+Shift+f" = "floating toggle";
        "${mod}+space" = "focus mode_toggle";
        "${mod}+Ctrl+greater" = "move workspace to output right";
        "${mod}+Ctrl+less" = "move workspace to output left";
        "${mod}+Shift+r" = "restart";

        "${mod}+d" = "exec rofi -show drun -show-icons";

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
      };
      bars = [
        {
          statusCommand = "${pkgs.i3status}/bin/i3status";
          position = "top";
          workspaceButtons = true;
        }
      ];
      gaps = {
        inner = 8;
        outer = 5;
        smartGaps = true;
        smartBorders = "on";
      };

      floating = {
        titlebar = false;
        border = 1;
        criteria = [
          {class = "^steam$";}
          {class = "^TeamSpeak$";}
          {class = "^WebCord$";}
        ];
      };

      terminal = "${pkgs.kitty}/bin/kitty";

      #fonts = {
      #  names = ["Roboto"];
      #  size = 13.0;
      #};
    };
  };
  fonts.fontconfig.enable = true;
}
