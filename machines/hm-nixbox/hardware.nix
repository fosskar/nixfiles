{ pkgs, ... }:
{

  boot = {
    kernelModules = [ "xe" ];

    # intel arc b50 pro needs pci=realloc for BAR allocation
    kernelParams = [ "pci=realloc" ];
  };

  hardware = {
    cpu.amd.updateMicrocode = true;

    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
        vpl-gpu-rt
      ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      #  clinfo
      #  vulkan-tools # vulkaninfo, vkcube for testing
      openvino
    ];
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
      # fix opencl icd path for nixos
      OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";
    };
  };
}
