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
      enable = false;
      settings = {
        terminal.vt = 1;
        default_session = {
          #command = "${lib.getExe config.programs.uwsm.package} start hyprland-uwsm.desktop";
          command = "${pkgs.tuigreet}/bin/tuigreet --greeting 'NixOS: unstable' --time --asterisks --remember --remember-user-session --theme 'border=cyan;button=yellow'";
          user = "simon";
        };
        #initial_session = default_session;
      };
    };
  };
  # this is a life saver.
  # literally no documentation about this anywhere.
  # might be good to write about this...
  # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
}
