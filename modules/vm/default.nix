{
  modulesPath,
  mylib,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../shared
  ]
  ++ (mylib.scanPaths ./. { exclude = [ ]; });

  services.qemuGuest.enable = lib.mkDefault true;

  systemd.services.qemu-guest-agent.path = [ pkgs.shadow ];
}
