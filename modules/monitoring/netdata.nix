{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.monitoring.netdata;
in
{
  # --- options ---

  options.nixfiles.monitoring.netdata = {
    enable = lib.mkEnableOption "netdata real-time monitoring";
  };

  config = lib.mkIf cfg.enable {
    # --- service ---

    services.netdata = {
      enable = true;
      package = pkgs.netdata.override { withCloudUi = true; };
      config = {
        global = {
          "bind to" = "127.0.0.1";
          "memory mode" = "ram";
          "debug log" = "none";
          "access log" = "none";
          "error log" = "syslog";
        };
        web = {
          "default port" = "19999";
        };
      };
    };

    # --- nginx ---

    nixfiles.nginx.vhosts.netdata.port = 19999;
  };
}
