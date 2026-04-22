{
  flake.modules.nixos.intelCpu = {
    hardware.enableRedistributableFirmware = true;

    # delegate cgroups for better resource management (gamemode, ananicy, etc.)
    systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";

    hardware.cpu.intel.updateMicrocode = true;

    # thermald for thermal management
    services.thermald.enable = true;
  };
}
