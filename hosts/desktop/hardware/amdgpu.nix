{ config, pkgs, ... }:
{
  environment = {
    variables = {
      AMD_VULKAN_ICD = "RADV";
      RADV_PERFTEST = "gpl,shader_object";
    };
  };

  environment.etc = {
    "drirc/00-low-latency.conf" = {
      text = ''
        <driconf>
           <device>
               <application name="Default">
                   <option name="vblank_mode" value="0" />
               </application>
           </device>
        </driconf>
      '';
    };
  };

  boot = {
    kernelModules = [
      "kvm-amd"
      #"amd-pstate" # only needed for kernel version between 5.17 and 6.1
      "zenpower"
    ];
    kernelParams = [
      "amd_pstate=active"
      "amd_pstate.shared_mem=1"
      "amdgpu.exp_hw_support=1"
    ];
    blacklistedKernelModules = [ "k10temp" ];
    extraModulePackages = [ config.boot.kernelPackages.zenpower ];
  };

  hardware = {
    amdgpu = {
      legacySupport.enable = false;
      initrd.enable = true;
      opencl.enable = false; # ROCM maybe for LLM
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
      extraPackages = with pkgs; [
        libva
        vaapiVdpau
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };
}
