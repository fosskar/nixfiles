{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.monitoring.victorialogs;
in
{
  options.nixfiles.monitoring.victorialogs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "victorialogs log aggregation";
    };
  };

  config = lib.mkIf cfg.enable {
    services.victorialogs = {
      enable = true;
      listenAddress = "127.0.0.1:9428";
    };
  };
}
