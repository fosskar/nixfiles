{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "brave.nix"
    ];
  };
}
