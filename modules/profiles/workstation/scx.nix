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
      default = true;
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
  };

  config = lib.mkIf cfg.enable {
    services.scx = {
      enable = true;
      package = pkgs.scx.rustscheds;
      inherit (cfg) scheduler;
    };
  };
}
