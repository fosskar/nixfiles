{
  flake.modules.nixos.amdCpu = {
    hardware.enableRedistributableFirmware = true;

    # delegate cgroups for better resource management (gamemode, ananicy, etc.)
    systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";

    hardware.cpu.amd = {
      updateMicrocode = true;
      ryzen-smu.enable = true;
    };

    # amd_pstate driver for better power/performance
    boot.kernelParams = [ "amd_pstate=active" ];
  };
}
