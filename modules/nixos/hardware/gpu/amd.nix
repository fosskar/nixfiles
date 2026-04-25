{
  flake.modules.nixos.amdGpu =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = lib.mkIf config.hardware.amdgpu.opencl.enable [ pkgs.rocmPackages.clr.icd ];
        };

        amdgpu = {
          initrd.enable = true;
          overdrive.enable = true;
          opencl.enable = true;
        };
      };

      environment.systemPackages = with pkgs; [
        clinfo
        vulkan-tools
        mesa-demos
        libva-utils
        radeontop
      ];

      users.groups.video.members = config.users.groups.wheel.members;

      services.xserver.videoDrivers = [ "modesetting" ];

      services.lact.enable = true;
    };
}
