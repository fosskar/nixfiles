{ mylib, ... }:
{
  imports = [
    ../../modules/lxc
    ../../modules/monitoring
  ]
  ++ (mylib.scanPaths ./. { });

  nixpkgs.hostPlatform = "x86_64-linux";
}
