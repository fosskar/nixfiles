_: {
  environment = {
    variables = {
      AMD_VULKAN_ICD = "RADV";
    };
  };

  boot = {
    kernelModules = [ "kvm-amd" ];
    kernelParams = [ "amd_pstate=active" ];
    blacklistedKernelModules = [ ];
    extraModulePackages = [ ];
  };

  hardware = {
    amdgpu = {
      legacySupport.enable = false;
      initrd.enable = true;
      opencl.enable = true; # ROCM maybe for LLM
      amdvlk = {
        enable = false; # I am using RADV
        #package = "";
        #settings = "";
        #support32Bit.enable = true;
        #support32Bit.package = [];
        #supportExperimental.enable = false;
      };
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      #extraPackages = with pkgs; [
      #  libva
      #  vaapiVdpau
      #  libvdpau-va-gl
      #];
      #extraPackages32 = with pkgs; [
      #  vaapiVdpau
      #  libvdpau-va-gl
      #];
    };
  };
}
