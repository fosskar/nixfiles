{ mylib, ... }:
{
  imports = [
    ../../modules/lxc
    ../../modules/monitoring
  ]
  ++ (mylib.scanPaths ./. { exclude = [ ]; });

  nixpkgs.hostPlatform = "x86_64-linux";
}
