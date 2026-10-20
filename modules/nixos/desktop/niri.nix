{
  flake.modules.nixos.niri =
    { pkgs, ... }:
    {
      programs.niri = {
        enable = true;
        package = pkgs.niri;
      };

      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

      # xwayland support via xwayland-satellite
      environment.systemPackages = [
        pkgs.xwayland-satellite
      ];
    };
}
