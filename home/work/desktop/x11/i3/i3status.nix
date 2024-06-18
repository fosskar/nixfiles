_: {
  programs.i3status = {
    enable = true;
    general = {
      output_format = "i3bar";
      colors = true;
      interval = 5;
    };
    modules = {
      "wireless _first_" = {
        position = 2;
        enable = true;
        settings = {
          format_up = " WiFi ";
          format_down = " WiFi ";
        };
      };
      "ethernet _first_" = {
        position = 3;
        enable = true;
        settings = {
          format_up = " Ethernet ";
          format_down = " Ethernet ";
        };
      };
      "battery all" = {
        position = 4;
        enable = true;
        settings = {
          format = " %status %percentage %remaining %emptytime ";
          format_down = " No battery ";
          status_chr = " ⚡CHR ";
          status_bat = " 🔋BAT ";
          status_unk = " ?UNK ";
          status_full = " ☻FULL ";
          path = "/sys/class/power_supply/BAT%d/uevent";
          low_threshold = 10;
        };
      };
      "path_exists VPN" = {
        enable = true;
        position = 1;
        settings = {
          format = " VPN ";
          format_down = " VPN";
          path = "/proc/sys/net/ipv4/conf/vpn0";
        };
      };
      "tztime local" = {
        position = 9;
        enable = true;
        settings = {
          format = " %d.%m.%y   %H:%M ";
        };
      };
      "memory" = {
        position = 6;
        enable = true;
        settings = {
          format = " %used ";
          threshold_degraded = "10%";
          format_degraded = " MEMORY: %free ";
        };
      };
      "load" = {
        position = 7;
        enable = true;
        settings = {
          format = "   %1min ";
        };
      };
      "disk /" = {
        position = 5;
        enable = true;
        settings = {
          format = " %free ";
        };
      };
      "volume master" = {
        position = 8;
        enable = true;
        settings = {
          format = " ♪:%volume ";
          format_muted = " ♪:muted ";
          device = "default";
          mixer = "Master";
          mixer_idx = 0;
        };
      };
      "ipv6" = {
        enable = false;
      };
    };
  };
}
