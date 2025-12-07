{ pkgs, lib, ... }:
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

    intel-gpu-tools.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      clinfo
      vulkan-tools # vulkaninfo, vkcube for testing
    ];
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
      # fix opencl icd path for nixos
      OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";
    };
  };

  services.udev.extraRules =
    let
      mkRule = as: lib.concatStringsSep ", " as;
      mkRules = rs: lib.concatStringsSep "\n" rs;
    in
    mkRules ([
      (mkRule [
        ''ACTION=="add|change"''
        ''SUBSYSTEM=="block"''
        ''KERNEL=="sd[a-z]"''
        ''ATTR{queue/rotational}=="1"''
        ''RUN+="${pkgs.hdparm}/bin/hdparm -B 90 -S 241 /dev/%k"''
      ])
    ]);
}
