{ mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "hyprpanel"
      "noctalia"
      #"dankmaterialshell"
    ];
  };
}
