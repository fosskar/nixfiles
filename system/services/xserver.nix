{pkgs, ...}: {
  services = {
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
  };
}
