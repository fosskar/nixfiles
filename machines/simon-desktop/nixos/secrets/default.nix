{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "agenix.nix"
    ];
  };
}
