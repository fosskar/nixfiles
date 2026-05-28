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

      environment.systemPackages = [
        pkgs.clinfo
        pkgs.vulkan-tools
        pkgs.mesa-demos
        pkgs.libva-utils
        pkgs.radeontop
      ];

      users.groups.video.members = lib.mkAfter config.users.groups.wheel.members;

      services.xserver.videoDrivers = [ "modesetting" ];

      services.lact.enable = true;

      preservation.preserveAt."/persist".directories = [
        "/etc/lact"
      ];
    };
}
