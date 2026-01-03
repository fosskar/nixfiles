{ mylib, ... }:
{
  imports = mylib.scanPaths ./. { exclude = [ "way-displays.nix" ]; };
}
