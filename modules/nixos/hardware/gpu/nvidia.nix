{
  flake.modules.nixos.nvidiaGpu =
    {
      config,
      pkgs,
      ...
    }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      environment.systemPackages = with pkgs; [
        clinfo
        vulkan-tools
        mesa-demos
        libva-utils
        nvtopPackages.nvidia
      ];

      users.groups.video.members = config.users.groups.wheel.members;

      hardware.nvidia = {
        powerManagement.enable = true;
        open = true;
      };

      services.xserver.videoDrivers = [ "nvidia" ];

    };
}
