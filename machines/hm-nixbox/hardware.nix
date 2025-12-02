# hardware configuration for hm-nixbox
# amd ryzen 5800x cpu with intel arc b50 pro discrete gpu
{ pkgs, ... }:
{

  boot = {
    # load xe driver at boot for intel arc gpu
    kernelModules = [ "xe" ];

    # intel arc b50 pro needs pci=realloc for BAR allocation
    kernelParams = [ "pci=realloc" ];
  };

  # amd microcode updates
  hardware = {
    cpu.amd.updateMicrocode = true;

    # firmware for intel arc gpu
    firmware = [ pkgs.linux-firmware ];

    # intel arc b50 pro gpu for video transcoding
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # vaapi driver
        intel-compute-runtime # opencl
        vpl-gpu-rt # intel quick sync video
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
