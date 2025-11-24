{
  pkgs,
  ...
}:
{

  # Intel GPU support
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        # Required for modern Intel GPUs (Xe iGPU and ARC)
        intel-media-driver # VA-API (iHD) userspace
        vpl-gpu-rt # oneVPL (QSV) runtime

        # Optional (compute / tooling):
        intel-compute-runtime # OpenCL (NEO) + Level Zero for Arc/Xe
        # NOTE: 'intel-ocl' also exists as a legacy package; not recommended for Arc/Xe.
        # libvdpau-va-gl       # Only if you must run VDPAU-only apps

        # Vulkan support for Intel Arc GPUs
        vulkan-loader
        vulkan-validation-layers
      ];
    };
    intel-gpu-tools.enable = true;
  };

  # Useful tools for testing
  environment = {
    systemPackages = with pkgs; [
      clinfo
      vulkan-tools # vulkaninfo, vkcube for testing
    ];
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD"; # Prefer the modern iHD backend
      # VDPAU_DRIVER = "va_gl";      # Only if using libvdpau-va-gl

      # Fix OpenCL ICD path for NixOS
      OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";
    };
  };

  # May help services that have trouble accessing /dev/dri (e.g., jellyfin/plex):
  # users.users.<service>.extraGroups = [ "video" "render" ];
}
