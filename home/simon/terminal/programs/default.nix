{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "zellij.nix" # disabled in home.nix
    ];
  };
}
