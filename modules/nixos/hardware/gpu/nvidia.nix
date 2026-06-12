{
  flake.modules.nixos.nvidiaGpu =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      nixpkgs.config = {
        allowUnsupportedSystem = lib.mkForce false;
        cudaCapabilities = [ "12.0" ];
      };

      boot.kernelParams = [ "pci=realloc" ];

      hardware.graphics.enable = true;

      environment.systemPackages = [
        pkgs.clinfo
        pkgs.vulkan-tools
        pkgs.libva-utils
        pkgs.nvtopPackages.nvidia
      ];

      users.groups.video.members = lib.mkAfter config.users.groups.wheel.members;

      hardware.nvidia = {
        branch = "beta";
        #package = config.boot.kernelPackages.nvidiaPackages.stable; # Default
        #package = config.boot.kernelPackages.nvidiaPackages.beta;
        #package = config.boot.kernelPackages.nvidiaPackages.production;

        # blackwell+ requires open modules
        open = true;
        modesetting.enable = true;
        nvidiaPersistenced = true;
      };

      hardware.nvidia-container-toolkit.enable = true;

      services.xserver.videoDrivers = [ "nvidia" ];
    };
}
