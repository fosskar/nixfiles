{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd
  ];
  environment.variables.AMD_VULKAN_ICD = "RADV";

  hardware = {
    #amdgpu.loadInInitrd = false;
    #amdgpu.amdvlk = true;
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
      ];
      extraPackages32 = with pkgs; [mangohud];
    };
  };
}
