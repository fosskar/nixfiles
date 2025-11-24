{ mylib, ... }:
{
  imports = mylib.scanPaths ./. { exclude = [ "apparmor.nix" ]; };
}
