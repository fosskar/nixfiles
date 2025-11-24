{
  modulesPath,
  lib,
  mylib,
  ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../shared
  ]
  ++ (mylib.scanPaths ./. { exclude = [ ]; });

  boot.isContainer = lib.mkForce true;

  proxmoxLXC = {
    manageNetwork = false;
    manageHostName = false;
    privileged = false;
  };
}
