{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.gpu.nvidia;
in
{
  config = lib.mkIf cfg.enable {
    hardware.nvidia = {
      powerManagement.enable = lib.mkDefault true;
      open = lib.mkDefault true;
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    environment.systemPackages = [ pkgs.nvtopPackages.nvidia ];
  };
}
