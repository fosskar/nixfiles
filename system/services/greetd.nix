{pkgs, ...}: {
  # greetd DM with tuigreet
  services = {
    greetd = {
      enable = true;
      settings = {
        default_session = {
          user = "simon";
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet -g LOGIN -t -r --sessions $HOME/.config/wayland-sessions:$HOME/.config/xsessions";
        };
      };
    };
  };
  security.pam.services.greetd.enableGnomeKeyring = true;
}
