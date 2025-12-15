{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.gpu.amd;
in
{
  config = lib.mkIf cfg.enable {
    hardware = {
      amdgpu = {
        initrd.enable = lib.mkDefault true;
        overdrive.enable = lib.mkIf cfg.lact.enable true;
        opencl.enable = lib.mkIf cfg.opencl.enable true;
      };
      graphics.extraPackages = lib.mkIf cfg.opencl.enable [
        pkgs.rocmPackages.clr.icd
      ];
    };

    services.xserver.videoDrivers = lib.mkDefault [ "modesetting" ];

    environment.systemPackages = [ pkgs.radeontop ];

    # lact for overclocking/fan control
    services.lact.enable = lib.mkIf cfg.lact.enable true;
  };
}
