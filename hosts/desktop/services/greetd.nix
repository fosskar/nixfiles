{
  config,
  lib,
  ...
}:
{
  # greetd DM with tuigreet
  services = {
    greetd =
      let
        session = {
          command = "${lib.getExe config.programs.uwsm.package} start hyprland-uwsm.desktop";
          user = "simon";
        };
      in
      {
        enable = true;
        settings = {
          terminal.vt = 1;
          initial_session = session;
          default_session = session;
        };
      };
  };

  programs.uwsm = {
    enable = true;
    waylandCompositors.hyprland = {
      binPath = "/run/current-system/sw/bin/Hyprland";
      prettyName = "Hyprland";
      comment = "Hyprland managed by UWSM";
    };
  };
}
