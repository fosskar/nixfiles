{
  pkgs,
  ...
}:
{
  # greetd DM with tuigreet
  #programs.regreet = {
  #  enable = true;
  #};
  services = {
    greetd = {
      enable = true;
      settings = {
        terminal.vt = 1;
        default_session = {
          #command = "${lib.getExe config.programs.uwsm.package} start hyprland-uwsm.desktop";
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --greeting 'NixOS: unstable' --time --asterisks --remember --remember-user-session  --theme 'border=cyan;button=yellow'";
          user = "simon";
        };
        #initial_session = default_session;
      };
    };
  };
}
