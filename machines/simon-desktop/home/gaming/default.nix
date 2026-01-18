{ mylib, ... }:
{
  imports = mylib.scanPaths ./. { exclude = [ "star-citizen.nix" ]; };
}
