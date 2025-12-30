{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.monitoring.beszel;
in
{
  options.nixfiles.monitoring.beszel = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "beszel monitoring hub and agent";
    };
  };

  config = lib.mkIf cfg.enable {
    # nginx reverse proxy for hub
    nixfiles.nginx.vhosts.beszel.port = config.services.beszel.hub.port;

    services.beszel.hub = {
      enable = true;
      host = "127.0.0.1";
      port = 8090;
    };
  };
}
