{
  flake.modules.nixos.intelGpu =
    {
      config,
      pkgs,
      ...
    }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          intel-media-driver
          intel-compute-runtime
          vpl-gpu-rt
        ];
      };

      environment.systemPackages = with pkgs; [
        clinfo
        vulkan-tools
        mesa-demos
        libva-utils
        nvtopPackages.intel
      ];

      users.groups.video.members = config.users.groups.wheel.members;

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
