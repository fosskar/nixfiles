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

      environment.systemPackages = with pkgs; [
        clinfo
        vulkan-tools
        libva-utils
        nvtopPackages.nvidia
      ];

      users.groups.video.members = config.users.groups.wheel.members;

      hardware.nvidia = {
        branch = "beta";
        #package = config.boot.kernelPackages.nvidiaPackages.stable; # Default
        #package = config.boot.kernelPackages.nvidiaPackages.beta;
        #package = config.boot.kernelPackages.nvidiaPackages.production;

        # Data center GPUs startin from Blackwell must use open-source modules
        # proprietary modules are no longer supported
        open = true;
        modesetting.enable = true;
        nvidiaPersistenced = true;
      };

      hardware.nvidia-container-toolkit.enable = true;

      services.xserver.videoDrivers = [ "nvidia" ];
    };
}
