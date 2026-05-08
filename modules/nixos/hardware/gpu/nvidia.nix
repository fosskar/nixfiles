{
  flake.modules.nixos.nvidiaGpu =
    {
      config,
      pkgs,
      ...
    }:
    {
      hardware.graphics.enable = true;

      environment.systemPackages = with pkgs; [
        clinfo
        vulkan-tools
        libva-utils
        nvtopPackages.nvidia
      ];

      users.groups.video.members = config.users.groups.wheel.members;

      hardware.nvidia = {
        open = true;
        modesetting.enable = true;
        nvidiaPersistenced = true;
      };

      hardware.nvidia-container-toolkit.enable = true;

      services.xserver.videoDrivers = [ "nvidia" ];
    };
}
