{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.scx;
in
{
  options.nixfiles.scx = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable sched_ext scheduler";
    };

    scheduler = lib.mkOption {
      type = lib.types.enum [
        "scx_lavd"
        "scx_rusty"
        "scx_rustland"
        "scx_bpfland"
      ];
      default = "scx_lavd";
      description = "sched_ext scheduler to use";
    };

    performance = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable performance mode";
    };
  };

  config = lib.mkIf cfg.enable {
    services.scx = {
      enable = true;
      package = pkgs.scx.rustscheds;
      inherit (cfg) scheduler;
      extraArgs = lib.mkIf cfg.performance [ "--performance" ];
    };
  };
}
