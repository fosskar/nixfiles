{
  mylib,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.srvos.nixosModules.mixins-terminfo
  ]
  ++ mylib.scanPaths ./. { };

  # srvos terminfo mixin has broken ghostty path (extracts from macOS bundle)
  # override with the correct package
  environment.systemPackages = [ pkgs.ghostty.terminfo ];
}
