{
  lib,
  config,
  ...
}:
let
  cfg = config.nixfiles.cpu.intel;
in
{
  config = lib.mkIf cfg.enable {
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # thermald for thermal management
    services.thermald.enable = lib.mkDefault true;
  };
}
