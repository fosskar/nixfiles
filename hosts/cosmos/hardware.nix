{
  inputs,
  config,
  pkgs,
  ...
}: {
  environment = {
    sessionVariables = {
      AMD_VULKAN_ICD = "RADV";
      #NIXOS_OZONE_WL = "1";	# break vscodium on wayland
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_WEBRENDER = "1";
    };
  };

  hardware = {
    bluetooth.enable = true;
    logitech.wireless.enable = true;

    cpu.amd.updateMicrocode = true;

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        goverlay
        mangohud
        vaapiVdpau
        libvdpau-va-gl
        gamescope
      ];
      extraPackages32 = with pkgs; [mangohud];
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
