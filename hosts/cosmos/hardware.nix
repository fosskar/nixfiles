{
  pkgs,
  ...
}: {
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

  hardware = {
    enableAllFirmware = true;
    bluetooth.enable = true;

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
}
