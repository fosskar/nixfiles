{ mylib, ... }:
{
  imports = [
    ../../modules/lxc
    ../../modules/backup
    ../../modules/monitoring
  ]
  ++ (mylib.scanPaths ./. { });

  nixpkgs.hostPlatform = "x86_64-linux";
}
