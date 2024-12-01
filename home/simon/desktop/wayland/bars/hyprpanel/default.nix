{
  lib,
  config,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.module.desktop.wayland.bar;
in
{

  config = mkIf (cfg == "hyprpanel") {
    home.packages = with pkgs; [
      hyprpanel
    ];
    systemd.user = {
      services.hyprpanel = {
        Unit = {
          Description = "HyprPanel - A Bar/Panel built with AGS for Hyprland.";
          Documentation = "https://github.com/Jas-SinghFSU/HyprPanel";
          PartOf = [
            "tray.target"
            "graphical-session.target"
          ];
          Before = "tray.target";
          After = "graphical-session.target";
        };

        Service = {
          ExecStart = "${pkgs.hyprpanel}/bin/hyprpanel";
          Restart = "on-failure";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
      targets.tray.Unit.After = lib.mkForce [ "hyprpanel.service" ];
    };
  };
}
