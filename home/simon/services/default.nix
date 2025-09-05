{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "kdeconnect.nix" # disabled in home.nix
    ];
  };
}
