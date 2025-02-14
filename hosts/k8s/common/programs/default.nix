{
  lib,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    ./xdg.nix
    ./zsh.nix
  ];
  programs = {
    # The lessopen package pulls in Perl.
    less.lessopen = mkDefault null;
    command-not-found.enable = mkDefault false;
  };
}
