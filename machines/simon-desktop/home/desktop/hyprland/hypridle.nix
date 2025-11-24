{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.hypridle = {
    enable = true;
    #package = inputs.hypridle.packages.${pkgs.system}.hypridle;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        before_sleep_cmd = "loginctl lock-session";
        lock_cmd = "pgrep hyprlock || ${lib.getExe config.programs.hyprlock.package}";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 900;
          on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
        }
        {
          timeout = 3600;
          on-timeout = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
    };
  };

  systemd.user.services = {
    hypridle = {
      Unit = {
        ConditionEnvironment = lib.mkForce [
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP=Hyprland"
        ];
      };
    };
  };
}
