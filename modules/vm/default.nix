{
  modulesPath,
  mylib,
  lib,
  pkgs,
  ...
}:
{
  # vm-specific settings - base/server imported by machine config
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ]
  ++ (mylib.scanPaths ./. { exclude = [ ]; });

  services.qemuGuest.enable = lib.mkDefault true;

  systemd.services.qemu-guest-agent.path = [ pkgs.shadow ];
}
