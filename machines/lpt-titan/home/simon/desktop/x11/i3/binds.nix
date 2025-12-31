{ pkgs, ... }:
{
  xsession.windowManager.i3 = {
    config =
      let
        mod = "Mod4";
        exe = "exec --no-startup-id";
      in
      {
        modifier = mod;
        keybindings = {
          "${mod}+t" = "${exe} ghostty";
          "${mod}+e" = "${exe} ghostty -e yazi";
          "${mod}+w" = "${exe} zen";
          "${mod}+s" = "${exe} slack";
          "${mod}+o" = "${exe} obsidian";
          "${mod}+z" = "${exe} zeditor";
          "${mod}+p" = "${exe} arandr";
          "${mod}+m" = "${exe} thunderbird";
          "${mod}+Shift+e" = "${exe} nautilus";
          "${mod}+Shift+q" = "kill";
          "Print" = "${exe} flameshot";
          "${mod}+Down" = "focus down";
          "${mod}+Up" = "focus up";
          "${mod}+Left" = "focus left";
          "${mod}+Right" = "focus right";
          "${mod}+Shift+Right" = "move right";
          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Ctrl+Left" = "resize grow left";
          "${mod}+Ctrl+Down" = "resize grow down";
          "${mod}+Ctrl+Up" = "resize grow up";
          "${mod}+Ctrl+Right" = "resize grow right";
          "${mod}+h" = "layout toggle split";
          "${mod}+Shift+v" = "split v";
          "${mod}+f" = "fullscreen";
          "${mod}+v" = "floating toggle";
          "${mod}+Ctrl+greater" = "move workspace to output right";
          "${mod}+Ctrl+less" = "move workspace to output left";
          "${mod}+space" = "${exe} rofi -show drun -show-icons";
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
          "${mod}+Shift+o" =
            "${exe} 'i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'";
          "${mod}+l" = "exec i3lock -c 232528";

          # mute mic
          "F9" = "${exe} pamixer --default-source -t";

          # keyboard multimedia keys
          "XF86AudioRaiseVolume" = "${exe} wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0";
          "XF86AudioLowerVolume" = "${exe} wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- --limit 0.0";
          "XF86AudioMute" = "${exe} wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86AudioPlay" = "${exe} playerctl play-pause";
          "XF86AudioPrev" = "${exe} playerctl previous";
          "XF86AudioNext" = "${exe} playerctl next";
          #"XF86MonBrightnessUp" = "${exe} ${pkgs.brightnessctl}/bin/bright set +5%";
          "XF86MonBrightnessUp" = "${exe} ${pkgs.xorg.xbacklight}/bin/xbacklight -inc 10";
          #"XF86MonBrightnessDown" = "${exe} ${brightnessctl} set  5%-";
          "XF86MonBrightnessDown" = "${exe} ${pkgs.xorg.xbacklight}/bin/xbacklight -dec 10";
        };
      };
  };
}
