{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    wlr.enable = false;
    config = {
      common.default = [ "*" ];
      hyprland.default = [
        "hyprland"
        "gtk"
      ];
    };
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
