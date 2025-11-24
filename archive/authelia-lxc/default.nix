{ mylib, ... }:
{
  imports = [
    ../../../../modules/lxc
  ]
  ++ (mylib.scanPaths ./. { exclude = [ ]; });

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
