{ mylib, inputs, ... }:
{
  imports = [
    inputs.srvos.nixosModules.server
    ../base
  ]
  ++ mylib.scanPaths ./. { };
}
