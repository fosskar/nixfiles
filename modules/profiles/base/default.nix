{
  mylib,
  inputs,
  ...
}:
{
  imports = [
    inputs.srvos.nixosModules.mixins-terminfo
  ]
  ++ mylib.scanPaths ./. { };
}
