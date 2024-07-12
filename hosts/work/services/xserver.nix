_: {
  environment.pathsToLink = [ "/libexec" ];

  services = {
    xserver = {
      enable = true;
      windowManager.i3.enable = true;
      displayManager = {
        startx.enable = true;
        lightdm.enable = false;
      };
      desktopManager = {
        xterm.enable = false;
      };
      # now defaults to "modesetting" driver anyways over device-specific.
      # other driver like "amdpgu", "nouveau" or "radeon" unmaintained: https://github.com/NixOS/nixpkgs/pull/218437
      videoDrivers = [ "modesetting" ];
    };
  };
}
