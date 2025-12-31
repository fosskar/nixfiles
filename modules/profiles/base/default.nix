{
  lib,
  mylib,
  inputs,
  ...
}:
{
  imports = [
    inputs.srvos.nixosModules.mixins-terminfo
  ] ++ mylib.scanPaths ./. { };

  # disable yggdrasil multicast - use explicit peers only (security)
  services.yggdrasil.settings.MulticastInterfaces = lib.mkForce [ ];
  services.yggdrasil.openMulticastPort = lib.mkForce false;

  # only allow peering from known machines
  services.yggdrasil.settings.AllowedPublicKeys = [
    "48366f4c85cd25f6d6e514928965559a0ab2e161b0ed9caf4e4d289f4ca71522" # simon-desktop
    "db01e0e96a4969bfa69a53c56646b0c3d3bbcc620a086f0f96174e915e6d16a5" # hm-nixbox
    "204f30349bc1818988ff47245a296be0d30d001af6ed7ad8c93e3f5af78dafa9" # hzc-pango
  ];
}
