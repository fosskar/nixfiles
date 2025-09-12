{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "anyrun.nix"
      "sherlock.nix"
    ];
  };
}
