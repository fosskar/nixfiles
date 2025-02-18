{ lib, ... }:
{
  xdg = {
    autostart.enable = lib.mkDefault false;
    icons.enable = lib.mkDefault false;
    menus.enable = lib.mkDefault false;
    mime.enable = lib.mkDefault false;
    sounds.enable = lib.mkDefault false;
  };
}
