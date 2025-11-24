{ pkgs, ... }:
{

  boot.kernelParams = [ "i915.enable_guc=3" ];

  # intel gpu support for arc b50 pro
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # required for modern intel gpus (xe igpu and arc)
      intel-media-driver # va-api (ihd) userspace
      vpl-gpu-rt
      intel-compute-runtime
    ];
  };

  # useful tools for testing
  environment = {
    systemPackages = with pkgs; [
      #  clinfo
      #  vulkan-tools # vulkaninfo, vkcube for testing
      openvino
    ];
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD"; # prefer the modern ihd backend
      # fix opencl icd path for nixos
      OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";
    };
  };
}
