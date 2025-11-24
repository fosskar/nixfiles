{
  pkgs,
  ...
}:
{
  services = {
    greetd = {
      enable = true;
      settings = {
        useTextGreeter = true;
        terminal.vt = 1;
        default_session = {
          #command = "${lib.getExe config.programs.uwsm.package} start hyprland-uwsm.desktop"; # not using uwsm anymore
          command = "${pkgs.tuigreet}/bin/tuigreet --greeting 'NixOS: unstable' --time --asterisks --remember --remember-user-session --theme 'border=cyan;button=yellow'";
          user = "greeter";
        };
        #initial_session = default_session;
      };
    };
  };
}
