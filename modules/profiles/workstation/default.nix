{ mylib, inputs, ... }:
{
  imports = [
    inputs.srvos.nixosModules.desktop
    ../base
  ] ++ mylib.scanPaths ./. { };
}
