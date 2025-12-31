{ mylib, ... }:
{
  imports = mylib.scanPaths ./. { };

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    systemd.enable = true;
    swaynag.enable = true;
  };
}
