# shared traefik reverse proxy base
# provides: entrypoints, acme, access log, metrics, geoblock middleware, persistence
# other modules add routes/services/middlewares via services.traefik merging
{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.traefik;
in
{
  # --- options ---

  options.nixfiles.traefik = {
    acmeEmail = lib.mkOption {
      type = lib.types.str;
      default = config.nixfiles.acme.email or "letsencrypt.unpleased904@passmail.net";
      description = "email for ACME/letsencrypt certificates (defaults to nixfiles.acme.email if available)";
    };

    accessLog = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable traefik access logging to /var/log/traefik/access.log";
    };

    metrics = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable prometheus metrics endpoint";
      };
      address = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:8082";
        description = "metrics entrypoint listen address";
      };
    };

    geoblock = {
      enable = lib.mkEnableOption "traefik geoblock middleware (blocks traffic by country)";
      blacklistMode = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "if true, use blockedCountries; if false, use allowedCountries";
      };
      allowedCountries = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "DE" ];
        description = "ISO 3166-1 alpha-2 country codes to allow (whitelist mode)";
      };
      blockedCountries = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "ISO 3166-1 alpha-2 country codes to block (blacklist mode)";
      };
    };
  };

  # --- service ---

  config = {
    services.traefik = {
      enable = true;

      staticConfigOptions = {
        log.level = lib.mkDefault "WARN";

        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
            };
          };
          websecure = {
            address = ":443";
            http.middlewares = lib.optional cfg.geoblock.enable "geoblock@file";
            http3 = { };
          };
        }
        // lib.optionalAttrs cfg.metrics.enable {
          metrics.address = cfg.metrics.address;
        };

        certificatesResolvers.letsencrypt.acme = {
          email = cfg.acmeEmail;
          storage = "/var/lib/traefik/acme.json";
          tlsChallenge = { };
        };

        metrics = lib.mkIf cfg.metrics.enable {
          prometheus = {
            entryPoint = "metrics";
            buckets = [
              0.1
              0.3
              1.2
              5.0
            ];
            addEntryPointsLabels = true;
            addRoutersLabels = true;
            addServicesLabels = true;
          };
        };

        accessLog = lib.mkIf cfg.accessLog {
          filePath = "/var/log/traefik/access.log";
          format = "json";
        };

        experimental = lib.mkIf cfg.geoblock.enable {
          plugins.geoblock = {
            moduleName = "github.com/PascalMinder/geoblock";
            version = "v0.3.3";
          };
        };
      };

      dynamicConfigOptions.http.middlewares = lib.mkIf cfg.geoblock.enable {
        geoblock.plugin.geoblock = {
          allowLocalRequests = true;
          logLocalRequests = false;
          logAllowedRequests = false;
          logApiRequests = false;
          api = "https://get.geojs.io/v1/ip/country/{ip}";
          apiTimeoutMs = 750;
          cacheSize = 25;
          forceMonthlyUpdate = true;
          allowUnknownCountries = false;
          blackListMode = cfg.geoblock.blacklistMode;
          countries =
            if cfg.geoblock.blacklistMode then cfg.geoblock.blockedCountries else cfg.geoblock.allowedCountries;
          addCountryHeader = true;
        };
      };
    };

    # --- persistence ---

    nixfiles.persistence.directories = [
      {
        directory = "/var/lib/traefik";
        user = "traefik";
        group = "traefik";
      }
    ];

    # --- systemd ---

    systemd.services.traefik.serviceConfig.StateDirectory = "traefik";

    systemd.tmpfiles.rules = lib.mkIf cfg.accessLog [
      "d /var/log/traefik 0755 traefik traefik -"
    ];

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [
        443 # HTTP/3 (QUIC)
      ];
    };
  };
}
