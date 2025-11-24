{ mylib, ... }:
{
  imports = [
    ../../modules/lxc
    ../../modules/monitoring
    ../../modules/shared
  ]
  ++ (mylib.scanPaths ./. { });

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.11";
}
