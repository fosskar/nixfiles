{
  flake.modules.nixos.niri =
    { inputs, pkgs, ... }:
    {
      programs.niri = {
        enable = true;
        package = inputs.niri-nix.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
      };

      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

      # xwayland support via xwayland-satellite
      environment.systemPackages = [
        inputs.niri-nix.packages.${pkgs.stdenv.hostPlatform.system}.xwayland-satellite-unstable
      ];
    };
}
