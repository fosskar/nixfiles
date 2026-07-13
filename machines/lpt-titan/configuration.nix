{
  self,
  nflib,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    self.modules.nixos.noctalia-greeter
    self.modules.nixos.amdGpu
    self.modules.nixos.amdCpu
    self.modules.nixos.lanzaboote
    self.modules.nixos.agentDesktop
    self.modules.nixos.arbor
    self.modules.nixos.t3code
    self.modules.nixos.yubikeyGpgSsh
    self.modules.nixos.yubikeyU2f
  ]
  ++ nflib.scanPaths ./. { };

  hardware.fw-fanctrl.enable = true;

  services.lact.enable = lib.mkForce false;

  # overdrive ppfeaturemask (0xfffd7fff) clears PP_GFXOFF_MASK; gfxoff is
  # required for s0i3 entry on strix point -> suspend never reached hw sleep
  hardware.amdgpu.overdrive.enable = lib.mkForce false;

  clan.core.deployment.requireExplicitUpdate = true;

  # scx_lavd crashed (rcu cpu stall) on this machine; use bpfland instead
  services.scx.scheduler = "scx_bpfland";
}
