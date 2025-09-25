{ pkgs, ... }:
{

  # needed for niri
  environment.systemPackages = [
    pkgs.xwayland-satellite
  ];
}
