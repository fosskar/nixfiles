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
    self.modules.nixos.t3code
    self.modules.nixos.usbguard
    self.modules.nixos.yubikeyGpgSsh
    self.modules.nixos.yubikeyU2f
  ]
  ++ nflib.scanPaths ./. { };

  hardware.fw-fanctrl.enable = true;

  services.lact.enable = lib.mkForce false;

  # overdrive ppfeaturemask (0xfffd7fff) clears PP_GFXOFF_MASK; gfxoff is
  # required for s0i3 entry on strix point -> suspend never reached hw sleep
  hardware.amdgpu.overdrive.enable = lib.mkForce false;

  # the crucial p310 counts every board power cut in s2idle as an unsafe
  # shutdown and as wear (~1 per minute asleep); d3cold off keeps it powered
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0xc0a9", ATTR{device}=="0x5426", ATTR{d3cold_allowed}="0"
  '';

  clan.core.deployment.requireExplicitUpdate = true;
}
