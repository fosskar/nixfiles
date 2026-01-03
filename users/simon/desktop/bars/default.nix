{ mylib, ... }:
{
  # both shell modules are imported; each uses mkIf internally
  # based on config.nixfiles.desktop.shell
  imports = mylib.scanPaths ./. { };
}
