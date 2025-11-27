{ mylib, ... }:
{
  imports = [
    ../../modules/lxc
    ../../modules/monitoring
  ]
  ++ (mylib.scanPaths ./. { exclude = [ "user-list.nix" ]; });

  nixpkgs.hostPlatform = "x86_64-linux";
}
