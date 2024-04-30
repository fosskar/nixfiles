{pkgs, ...}: {
  xdg.portal = {
    enable = true;
    config = {
      common.default = ["gtk"];
      hyprland.default = ["gtk" "hyprland"];
    };
    wlr.enable = true;
    xdgOpenUsePortal = false;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };
}
