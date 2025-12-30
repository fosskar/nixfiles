{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.pangolin;
in
{
  options.services.pangolin = {
    # local-only mode (no gerbil/wireguard tunnels)
    localOnly = lib.mkEnableOption "local-only mode (disables gerbil tunnel service)";

    # maxmind geoip for pangolin resource-level blocking
    maxmindGeoip = {
      enable = lib.mkEnableOption "MaxMind GeoIP database for pangolin resource-level geo blocking";
    };

    # traefik-level geoblock
    geoblock = {
      enable = lib.mkEnableOption "traefik geoblock middleware (blocks traffic by country at reverse proxy level)";
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

    # crowdsec bouncer for traefik
    crowdsec = {
      enable = lib.mkEnableOption "crowdsec bouncer middleware for traefik";
      lapiKeyFile = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/crowdsec/traefik-bouncer-api-key.cred";
        description = "path to file containing crowdsec LAPI key for traefik bouncer";
      };
      lapiHost = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:8080";
        description = "crowdsec LAPI host:port";
      };
    };
  };

  config = {

    # maxmind geoipupdate service (optional)
    sops.secrets."geoip-license-key" = lib.mkIf cfg.maxmindGeoip.enable { };

    services.geoipupdate = lib.mkIf cfg.maxmindGeoip.enable {
      enable = true;
      interval = lib.mkDefault "weekly";
      settings = {
        AccountID = 1267557;
        LicenseKey = config.sops.secrets."geoip-license-key".path;
        EditionIDs = [ "GeoLite2-Country" ];
        DatabaseDirectory = "/var/lib/GeoIP";
      };
    };

    # persist pangolin data if impermanence is enabled
    environment.persistence."/persist".directories = lib.mkIf (
      config.environment.persistence ? "/persist"
    ) ([ "/var/lib/pangolin" ] ++ lib.optional cfg.maxmindGeoip.enable "/var/lib/GeoIP");

    services.pangolin = {
      enable = lib.mkDefault true;

      package = lib.mkDefault pkgs.custom.fosrl-pangolin;

      openFirewall = lib.mkDefault true;
      letsEncryptEmail = lib.mkDefault "letsencrypt.unpleased904@passmail.net";

      settings = {
        app.telemetry = {
          enabled = lib.mkForce false;
        };
        server = lib.mkIf cfg.maxmindGeoip.enable {
          maxmind_db_path = "/var/lib/GeoIP/GeoLite2-Country.mmdb";
        };
        flags = {
          disable_signup_without_invite = true;
          disable_user_create_org = true;
          enable_integration_api = true;
          allow_raw_resources = lib.mkDefault true;
        };
      };
    };

    # traefik config
    services.traefik = {
      # defaults
      staticConfigOptions = {
        log.level = lib.mkDefault "WARN";
        api = {
          dashboard = lib.mkDefault true;
          insecure = lib.mkDefault false;
        };
        entryPoints.metrics.address = lib.mkDefault "127.0.0.1:8082";
        metrics.prometheus = {
          entryPoint = lib.mkDefault "metrics";
          buckets = lib.mkDefault [
            0.1
            0.3
            1.2
            5.0
          ];
          addEntryPointsLabels = lib.mkDefault true;
          addRoutersLabels = lib.mkDefault true;
          addServicesLabels = lib.mkDefault true;
        };
        # access log with geoblock country header
        accessLog = lib.mkIf cfg.geoblock.enable {
          format = "json";
          filePath = "/var/log/traefik/access.log";
          fields.headers = {
            defaultMode = "drop";
            names.X-IPCountry = "keep";
          };
        };
        # security plugins
        experimental.plugins = lib.mkMerge [
          (lib.mkIf cfg.geoblock.enable {
            geoblock = {
              moduleName = "github.com/PascalMinder/geoblock";
              version = "v0.3.3";
            };
          })
          (lib.mkIf cfg.crowdsec.enable {
            crowdsec-bouncer = {
              moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
              version = "v1.4.6";
            };
          })
        ];
        # combine middlewares based on what's enabled (crowdsec first, then geoblock)
        entryPoints.websecure.http.middlewares = lib.mkIf (cfg.geoblock.enable || cfg.crowdsec.enable) (
          lib.optional cfg.crowdsec.enable "crowdsec@file" ++ lib.optional cfg.geoblock.enable "geoblock@file"
        );
      };
      dynamicConfigOptions.http.middlewares = lib.mkMerge [
        (lib.mkIf cfg.geoblock.enable {
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
        })
        (lib.mkIf cfg.crowdsec.enable {
          crowdsec.plugin.crowdsec-bouncer = {
            enabled = true;
            crowdsecLapiKeyFile = cfg.crowdsec.lapiKeyFile;
            crowdsecLapiHost = cfg.crowdsec.lapiHost;
            crowdsecMode = "live";
            forwardedHeadersTrustedIPs = [
              "127.0.0.1/32"
              "10.0.0.0/8"
              "172.16.0.0/12"
              "192.168.0.0/16"
            ];
          };
        })
      ];
    };

    systemd.services = {
      # reduce shutdown timeout for faster reboots
      # pangolin doesn't gracefully close websocket tunnels on SIGTERM
      pangolin = {
        serviceConfig = {
          TimeoutStopSec = lib.mkDefault 10;
        };
        # run database migrations before starting pangolin
        preStart = lib.mkAfter ''
          ${config.services.pangolin.package}/bin/pangolin-migrate || true
        '';
      };

      # local-only mode: disable gerbil and adjust traefik dependencies
      gerbil.enable = lib.mkIf cfg.localOnly false;
      traefik = lib.mkIf cfg.localOnly {
        requires = lib.mkForce [ "network.target" ];
        after = lib.mkForce [
          "network.target"
          "pangolin.service"
        ];
        wants = [ "pangolin.service" ];
      };
    };
  };
}
