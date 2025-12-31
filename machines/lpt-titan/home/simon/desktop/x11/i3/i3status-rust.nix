_: {
  programs.i3status-rust = {
    enable = true;
    bars = {
      custom = {
        blocks = [
          #{
          #  block = "net";
          #  format = " $icon ";
          #  format_alt = " IP: $ip ^icon_net_down $speed_down.eng(prefix:K) ^icon_net_up $speed_up.eng(prefix:K) ";
          #}
          {
            block = "cpu";
            format = " $icon   $utilization ";
            format_alt = " $icon   $barchart Freq: $frequency Boost: $boost ";
          }
          {
            block = "memory";
            format = " $icon   $mem_used_percents.eng(w:2) ";
            format_alt = " $icon_swap   zram: $zram_compressed.eng(w:2) $zram_decompressed.eng(w:2) ";
          }
          {
            block = "disk_space";
            format = "$icon   $percentage ";
            format_alt = " $icon   $available ";
            interval = 2000;
          }
          {
            block = "backlight";
            invert_icons = true;
          }
          {
            block = "sound";
            format = " $icon  {$volume.eng(w:2) |}";
            max_vol = 100;
            headphones_indicator = true;
            click = [
              {
                button = "left";
                cmd = "pwvucontrol --tab=3";
              }
            ];
            mappings = {
              "alsa_output.usb-SteelSeries_Arctis_Nova_Pro_Wireless-00.analog-stereo" = " ";
            };
          }
          {
            block = "sound";
            device_kind = "source";
            format = "$icon ";
            max_vol = 100;
            click = [
              {
                button = "left";
                cmd = "pwvucontrol --tab=4";
              }
            ];
          }
          {
            block = "battery";
            full_format = " $icon   $percentage ";
            format = " $icon   $percentage $time ";
            info = 50;
            good = 60;
            warning = 30;
            critical = 15;
          }
          {
            block = "time";
            format = " $icon   $timestamp.datetime() ";
            interval = 60;
          }
          {
            block = "notify";
            format = " $icon {$paused{Off}|On} {($notification_count.eng(w:1)) |} ";
            click = [
              {
                button = "right";
                action = "show";
              }
              {
                button = "left";
                action = "toggle_paused";
              }
            ];
          }
        ];

        settings = {
          icons = {
            icons = "awesome4";
          };
          theme = {
            theme = "semi-native";
            overrides = {
              separator = " | ";
            };
          };
        };
      };
    };
  };
}
