{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.monitoring.netdata;
  acmeDomain = config.nixfiles.caddy.domain;
  serviceDomain = "netdata.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 19999;
  internalUrl = "http://${bindAddress}:${toString port}";
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
          "bind to" = bindAddress;
          "memory mode" = "ram";
          "debug log" = "none";
          "access log" = "none";
          "error log" = "syslog";
        };
        web = {
          "default port" = toString port;
        };
      };
    };

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Netdata";
        category = "Monitoring";
        icon = "netdata.svg";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "Netdata";
        url = "https://${serviceDomain}";
        group = "Monitoring";
      }
    ];

    # --- caddy ---

    nixfiles.caddy.vhosts.netdata = {
      inherit port;
    };
  };
}
