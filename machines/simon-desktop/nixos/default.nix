{ mylib, ... }:
{
  imports = [
    ../../../modules/tailscale
  ]
  ++ mylib.scanPaths ./. { };

  nixfiles.tailscale.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";

  ### DON'T TOUCH!
  system.stateVersion = "24.11";
}
