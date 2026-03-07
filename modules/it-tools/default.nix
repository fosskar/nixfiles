{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.it-tools;
  acmeDomain = config.nixfiles.acme.domain;
  serviceDomain = "tools.${acmeDomain}";
  bindAddress = "127.0.0.1";
  inherit (cfg) port;
  internalUrl = "http://${bindAddress}:${toString port}";
in
{
  # --- options ---

  options.nixfiles.it-tools = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 8087;
      description = "port for it-tools";
    };
  };

  config = {
    # --- service ---

    systemd.services.it-tools = {
      description = "it-tools static web server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.darkhttpd}/bin/darkhttpd ${pkgs.it-tools}/lib --port ${toString port} --addr ${bindAddress}";
        DynamicUser = true;
        Restart = "on-failure";
      };
    };

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "IT Tools";
        category = "Documents";
        icon = "it-tools.svg";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "IT Tools";
        url = "https://${serviceDomain}";
        group = "Documents";
      }
    ];

    # --- nginx ---

    nixfiles.nginx.vhosts.tools = {
      inherit port;
    };
  };
}
