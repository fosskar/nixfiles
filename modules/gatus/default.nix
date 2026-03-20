{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.gatus;
  port = 8700;
  bindAddress = "127.0.0.1";
  internalUrl = "http://${bindAddress}:${toString port}";

  endpointModule = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "display name for the endpoint";
      };
      url = lib.mkOption {
        type = lib.types.str;
        description = "URL to monitor (usually internalUrl)";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "group/category for the endpoint";
      };
      interval = lib.mkOption {
        type = lib.types.str;
        default = "5m";
        description = "check interval";
      };
      conditions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "[STATUS] == 200" ];
        description = "health check conditions";
      };
    };
  };

  # convert to gatus endpoint format
  gatusEndpoints = map (
    ep:
    {
      inherit (ep)
        name
        url
        interval
        conditions
        ;
      enabled = true;
      alerts = [
        { type = "ntfy"; }
      ];
    }
    // lib.optionalAttrs (ep.group != "") { inherit (ep) group; }
  ) cfg.endpoints;
in
{
  # --- options ---

  options.nixfiles.gatus = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable gatus uptime monitoring";
    };

    endpoints = lib.mkOption {
      type = lib.types.listOf endpointModule;
      default = [ ];
      description = "auto-registered gatus health check endpoints from service modules";
    };
  };

  config = lib.mkIf cfg.enable {
    # --- service ---

    services.gatus = {
      enable = true;
      environmentFile = config.clan.core.vars.generators.ntfy.files."token-env".path;
      settings = {
        web.port = port;
        storage = {
          type = "sqlite";
          path = "/var/lib/gatus/gatus.db";
        };
        alerting.ntfy = {
          topic = "gatus";
          url = "http://127.0.0.1:8091";
          token = "$NTFY_TOKEN";
          priority = 4;
          default-alert = {
            enabled = true;
            failure-threshold = 2;
            success-threshold = 2;
            send-on-resolved = true;
          };
        };
        endpoints = gatusEndpoints;
      };
    };

    # --- backup ---

    clan.core.state.gatus = {
      folders = [ "/var/backup/gatus" ];
      preBackupScript = ''
        export PATH=${
          lib.makeBinPath [
            pkgs.sqlite
            pkgs.coreutils
          ]
        }
        mkdir -p /var/backup/gatus
        sqlite3 /var/lib/gatus/gatus.db ".backup '/var/backup/gatus/gatus.db'"
      '';
    };

    # --- caddy ---

    nixfiles.caddy.vhosts.gatus = {
      inherit port;
    };

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Gatus";
        category = "Monitoring";
        icon = "gatus.svg";
        href = "https://gatus.${config.nixfiles.caddy.domain}";
        siteMonitor = internalUrl;
      }
    ];
  };
}
