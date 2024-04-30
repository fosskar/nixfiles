{pkgs, ...}: {
  services = {
    libinput = {
      enable = true;
      mouse = {
        accelProfile = "flat";
        accelSpeed = "0";
      };
    };
    xserver = {
      enable = true;
      displayManager.startx.enable = true;
      displayManager.lightdm.enable = false;
      desktopManager = {
        xterm.enable = false;
      };
      # now defaults to "modesetting" driver anyways over device-specific.
      # other driver like "amdpgu", "nouveau" or "radeon" unmaintained: https://github.com/NixOS/nixpkgs/pull/218437
      videoDrivers = ["modesetting"];
    };
    ## greetd DM with tuigreet
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
}
