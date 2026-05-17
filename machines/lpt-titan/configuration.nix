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
    self.modules.nixos.greetd
    self.modules.nixos.nostrChat
    self.modules.nixos.amdGpu
    self.modules.nixos.amdCpu
    self.modules.nixos.lanzaboote
    self.modules.nixos.agentDesktop
    self.modules.nixos.arbor
    self.modules.nixos.t3code
    self.modules.nixos.yubikeyGpgSsh
    self.modules.nixos.yubikeyU2f
  ]
  ++ mylib.scanPaths ./. { };

  services.lact.enable = lib.mkForce false;

  # scx_lavd crashed (rcu cpu stall) on this machine; use bpfland instead
  services.scx.scheduler = "scx_bpfland";

}
