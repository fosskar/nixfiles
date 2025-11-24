{ mylib, ... }:
{
  imports = mylib.scanPaths ./. { exclude = [ "samba-mount.nix" ]; };
}
