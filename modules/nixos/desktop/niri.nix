{
  flake.modules.nixos.niri =
    { pkgs, ... }:
    {
      programs.niri = {
        enable = true;
        package = pkgs.niri;
      };

      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      # niri 26.04 lacks org.gnome.Shell GrabAccelerators, so gnome's GlobalShortcuts
      # fails BindShortcuts; hiding it makes apps like hex fall back to niri binds
      # https://redirect.github.com/niri-wm/niri/pull/4744
      xdg.portal.config.niri."org.freedesktop.impl.portal.GlobalShortcuts" = "none";

      # xwayland support via xwayland-satellite
      environment.systemPackages = [
        pkgs.xwayland-satellite
      ];
    };
}
