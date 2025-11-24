{
  lib,
  mylib,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  imports = mylib.scanPaths ./. { };
  programs = {
    # The lessopen package pulls in Perl.
    less.lessopen = mkDefault null;
    command-not-found.enable = mkDefault false;
  };
}
