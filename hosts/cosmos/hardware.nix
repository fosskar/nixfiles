{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [inputs.chaotic.nixosModules.default];

  environment = {
    sessionVariables = {
      AMD_VULKAN_ICD = "RADV";
    };
  };

  chaotic = {
    mesa-git = {
      enable = true;
    };
  };

  hardware = {
    bluetooth.enable = true;
    logitech.wireless.enable = true;

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
        vaapiVdpau
        libvdpau-va-gl
        rocmPackages.clr
        rocmPackages.clr.icd
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
    #fancontrol = {
    #  enable = true;
    #  config =
    #};
  };

  programs.corectrl = {
    enable = true;
    gpuOverclock = {
      enable = true;
      ppfeaturemask = "0xffffffff";
    };
  };
}
