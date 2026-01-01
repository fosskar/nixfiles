{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "noctalia"
      #"dankmaterialshell"
    ];
  };
}
