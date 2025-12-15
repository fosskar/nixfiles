{ lib, mylib, ... }:
{
  imports = mylib.scanPaths ./. { };

  config = {
    hardware.enableRedistributableFirmware = lib.mkDefault true;

    # delegate cgroups for better resource management (gamemode, ananicy, etc.)
    systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";
  };

  options.nixfiles.cpu = {
    amd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "enable AMD CPU optimizations";
      };
      pstate.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable amd_pstate driver (active mode)";
      };
      smu.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable ryzen-smu for detailed power/temp monitoring";
      };
    };

    intel = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "enable Intel CPU optimizations";
      };
    };
  };
}
