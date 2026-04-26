{
  self,
  mylib,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    self.modules.nixos.dmsGreeter
    self.modules.nixos.nostrChat
    self.modules.nixos.amdGpu
    self.modules.nixos.amdCpu
    self.modules.nixos.lanzaboote
  ]
  ++ mylib.scanPaths ./. { };

  services.lact.enable = lib.mkForce false;

  # scx_lavd crashed (rcu cpu stall) on this machine; use bpfland instead
  services.scx.scheduler = "scx_bpfland";

}
