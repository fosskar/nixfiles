{ lib, osConfig, ... }:
{
  # after noctalia.service (Type=notify), so the tray watcher exists when steam registers its icon
  systemd.user.services.steam = {
    Unit = {
      Description = "Steam";
      PartOf = [ "graphical-session.target" ];
      After = [
        "graphical-session.target"
        "noctalia.service"
      ];
    };
    Service.ExecStart = "${lib.getExe' osConfig.programs.steam.package "steam"} -silent";
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
