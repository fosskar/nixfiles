{ inputs, pkgs, ... }:
{
  imports = [
    inputs.niri-flake.nixosModules.niri
  ];

  programs.niri = {
    enable = true;
    package = inputs.niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
  };

  # disable niri-flake's polkit agent - using dms built-in
  systemd.user.services.niri-flake-polkit.enable = false;
}
