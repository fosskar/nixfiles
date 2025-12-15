{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.gpu.intel;
in
{
  config = lib.mkIf cfg.enable {
    boot = {
      kernelModules = [ "xe" ];
      # intel arc needs pci=realloc for resizable BAR allocation
      kernelParams = [ "pci=realloc" ];
    };

    hardware = {
      graphics.extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
        vpl-gpu-rt
      ];
      # intel-gpu-tools only works with i915, not xe driver
      # intel-gpu-tools.enable = lib.mkDefault true;
    };

    # nvtop supports xe driver for intel arc
    environment.systemPackages = [ pkgs.nvtopPackages.intel ];

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
      # fix opencl icd path for nixos
      OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";
    };
  };
}
