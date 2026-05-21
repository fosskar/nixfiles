{
  flake.modules.nixos.intelGpu =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [
          pkgs.intel-media-driver
          pkgs.intel-compute-runtime
          pkgs.vpl-gpu-rt
        ];
      };

      environment.systemPackages = [
        pkgs.clinfo
        pkgs.vulkan-tools
        pkgs.mesa-demos
        pkgs.libva-utils
        pkgs.nvtopPackages.intel
      ];

      users.groups.video.members = lib.mkAfter config.users.groups.wheel.members;

      boot = {
        kernelModules = [ "xe" ];
        # intel arc needs pci=realloc for resizable BAR allocation
        kernelParams = [ "pci=realloc" ];
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "iHD";
        # fix opencl icd path for nixos
        OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";
      };

      # enable runtime power management for intel gpu
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{class}=="0x030000", ATTR{power/control}="auto"
      '';
    };
}
