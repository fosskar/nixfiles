{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "vscodium.nix"
    ];
  };
}
