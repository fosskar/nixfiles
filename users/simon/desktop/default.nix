{ lib, mylib, ... }:
{
  imports = mylib.scanPaths ./. { };

  options.nixfiles.desktop.shell = lib.mkOption {
    type = lib.types.enum [
      "dms"
      "noctalia"
      "none"
    ];
    default = "noctalia";
    description = "which quickshell-based shell to use for desktop widgets";
  };
}
