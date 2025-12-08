{
  modulesPath,
  lib,
  mylib,
  ...
}:
{
  # lxc-specific settings - base/server imported by image config
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ]
  ++ (mylib.scanPaths ./. { exclude = [ ]; });

  boot.isContainer = lib.mkForce true;

  proxmoxLXC = {
    manageNetwork = false;
    manageHostName = false;
    privileged = false;
  };
}
