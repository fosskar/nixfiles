{
  self,
  mylib,
  lib,
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    self.modules.nixos.tuned
    self.modules.nixos.amdGpu
    self.modules.nixos.amdCpu
    self.modules.nixos.lanzaboote
    self.modules.nixos.bcachefs
    self.modules.nixos.preservation
  ]
  ++ mylib.scanPaths ./. { };

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.hostName = "lpt-titan";

  programs.nh.flake = "${config.users.users.simon.home}/code/nixfiles";

  clan.core = {
    settings.machine-id.enable = true;
    deployment.requireExplicitUpdate = true;
  };

  # iGPU: disable rocmPackages.clr.icd + lact (not needed)
  hardware.amdgpu.opencl.enable = lib.mkForce false;
  services.lact.enable = lib.mkForce false;

  # scx_lavd crashed (rcu cpu stall) on this machine; use bpfland instead
  services.scx.scheduler = "scx_bpfland";

  preservation.rollback = {
    type = "bcachefs";
    subvolume = "@root";
  };
}
