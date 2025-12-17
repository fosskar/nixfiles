{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
    ];
  };
}
