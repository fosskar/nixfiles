{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "dms.nix"
    ];
  };
}
