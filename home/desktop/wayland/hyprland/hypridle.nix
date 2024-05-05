{
  config,
  lib,
  pkgs,
  ...
}: let
  suspendScript = pkgs.writeShellScript "suspend-script" ''
    ${pkgs.pipewire}/bin/pw-cli i all 2>&1 | ${pkgs.ripgrep}/bin/rg running -q
    # only suspend if audio isn't running
    if [ $? == 1 ]; then
      ${pkgs.systemd}/bin/systemctl suspend
    fi
  '';
in {
  services.hypridle = {
    enable = true;
    settings = {
      beforeSleepCmd = "${pkgs.systemd}/bin/loginctl lock-session";
      afterSleepCmd = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on";
      lockCmd = lib.getExe config.programs.hyprlock.package;

      listeners = [
        {
          timeout = 180;
          onTimeout = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms off";
          onResume = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on";
        }
        {
          timeout = 3600;
          onTimeout = suspendScript.outPath;
        }
      ];
    };
  };
}
