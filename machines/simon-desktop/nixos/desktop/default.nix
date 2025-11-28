{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "tuigreet.nix"
    ];
  };
}
