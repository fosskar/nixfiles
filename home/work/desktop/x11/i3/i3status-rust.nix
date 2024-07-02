{ ... }:
{
  programs.i3status-rust = {
    enable = true;
    bars = {
      custom = {
        blocks = [
          {
            block = "custom";
            json = true;
            command = ''
              if ip link show vpn0 &>/dev/null && ip addr show vpn0 | grep -q 'inet '; then
                echo '{"text": " VPN ", "state": "Good"}'
              else
                echo '{"text": " VPN ", "state": "Critical"}'
              fi
            '';
            interval = 5;
          }
          {
            block = "net";
            interval = 5;
            format = " $icon ";
            format_alt = " ^icon_net_down $speed_down.eng(prefix:K) ^icon_net_up $speed_up.eng(prefix:K) ";
          }
          { block = "cpu"; }
          { block = "load"; }
          {
            block = "disk_space";
            interval = 200;
          }
          { block = "backlight"; }
          {
            block = "sound";
            max_vol = 100;
            click = [
              {
                button = "left";
                cmd = "pavucontrol --tab=4";
              }
            ];
          }
          {
            block = "battery";
            full_format = " $icon $percentage ";
            info = 50;
            good = 60;
            warning = 30;
            critical = 15;
          }
          {
            block = "time";
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
            theme = "dracula";
            overrides = {
              separator = "";
            };
          };
        };
      };
    };
  };
}
