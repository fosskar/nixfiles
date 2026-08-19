{
  flake.modules.nixos.amdCpu =
    { config, ... }:
    let
      # linux 7.2 dropped the transitive include that gave smu.c cpuid_eax and
      # cpuid_ebx; drop this once nixpkgs' ryzen-smu source carries the include
      ryzen-smu = config.boot.kernelPackages.ryzen-smu.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace smu.c \
            --replace-fail '#include <asm/io.h>' '#include <asm/cpuid/api.h>${"\n"}#include <asm/io.h>'
        '';
      });
    in
    {
      hardware.enableRedistributableFirmware = true;

      # delegate cgroups for better resource management (gamemode, ananicy, etc.)
      systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";

      hardware.cpu.amd.updateMicrocode = true;

      # hardware.cpu.amd.ryzen-smu.enable would use the unpatched package
      boot.kernelModules = [ "ryzen-smu" ];
      boot.extraModulePackages = [ ryzen-smu ];
      environment.systemPackages = [ ryzen-smu ];

      # amd_pstate driver for better power/performance
      boot.kernelParams = [ "amd_pstate=active" ];
    };
}
