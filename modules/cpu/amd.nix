{
  lib,
  config,
  ...
}:
let
  cfg = config.nixfiles.cpu.amd;
in
{
  config = lib.mkIf cfg.enable {
    hardware.cpu.amd = {
      updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      ryzen-smu.enable = lib.mkIf cfg.smu.enable true;
    };

    # amd_pstate driver for better power/performance
    boot.kernelParams = lib.mkIf cfg.pstate.enable [ "amd_pstate=active" ];
  };
}
