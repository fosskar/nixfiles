{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # do not suspend when audio is running
  suspendScript = pkgs.writeShellScript "suspend-script" ''
    ${lib.getExe pkgs.playerctl} -a status | ${lib.getExe pkgs.ripgrep} Playing -q
    if [ $? == 1 ]; then
      ${pkgs.systemd}/bin/systemctl suspend
    fi
  '';

  # do not shut off monitor when audio is running but not focused
  dpmsScript = pkgs.writeShellScript "dmps-script" ''
    ${lib.getExe pkgs.playerctl} -a status | ${lib.getExe pkgs.ripgrep} Playing -q
    if [ $? == 1 ]; then
      hyprctl dispatch dpms off
    fi
  '';
in
{
  services.hypridle = {
    enable = true;
    package = inputs.hypridle.packages.${pkgs.system}.hypridle;
    settings = {
      general = {
        before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
        lock_cmd = lib.getExe config.programs.hyprlock.package;
        after_sleep_cmd = "hyprctl dispatch dpms on"; # for faster wakeup after sleep
        ignore_dbus_inhibit = false; # whether to ignore dbus-sent idle-inhibit requests (used by e.g. firefox or steam)
      };
      listener = [
        {
          timeout = 180;
          on-timeout = dpmsScript.outPath;
          on-resume = "hyprctl dispatch dpms on";
        }
        # at the time no suspend please iam running llm in my local network until better solution like own server?!?!
        #{
        #  timeout = 3600;
        #  on-timeout = suspendScript.outPath;
        #}
      ];
    };
  };
}
