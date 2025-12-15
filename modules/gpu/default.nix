{
  lib,
  mylib,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./. { };

  config = {
    hardware.graphics = {
      enable = lib.mkDefault true;
      enable32Bit = lib.mkDefault true;
    };

    environment.systemPackages = with pkgs; [
      clinfo # opencl info
      vulkan-tools # vulkaninfo, vkcube
      mesa-demos # glxinfo, glxgears
      libva-utils # vainfo for video acceleration
    ];
  };

  options.nixfiles.gpu = {
    amd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "enable AMD GPU support";
      };
      opencl.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable OpenCL/ROCm support";
      };
      lact.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable LACT for overclocking/fan control";
      };
    };

    nvidia = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "enable NVIDIA GPU support";
      };
    };

    intel = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "enable Intel GPU support";
      };
    };
  };
}
