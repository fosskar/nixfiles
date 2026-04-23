{
  flake.modules.nixos.pangolin =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.pangolin;
      geoipDir = "/var/lib/GeoIP";
    in
    {
      options.services.pangolin = {
        localOnly = lib.mkEnableOption "local-only mode (disables gerbil tunnel service)";
        maxmindGeoip = lib.mkEnableOption "MaxMind GeoIP database for pangolin resource-level geo blocking";

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
        clan.core.vars.generators.geoip = lib.mkIf cfg.maxmindGeoip {
          files.license-key.secret = true;
          prompts.key = {
            description = "MaxMind GeoLite2 license key";
            persist = true;
          };
          script = "cat $prompts/key > $out/license-key";
        };

        services.geoipupdate = lib.mkIf cfg.maxmindGeoip {
          enable = true;
          interval = lib.mkDefault "weekly";
          settings = {
            AccountID = 1267557;
            LicenseKey = config.clan.core.vars.generators.geoip.files.license-key.path;
            EditionIDs = [ "GeoLite2-Country" ];
            DatabaseDirectory = geoipDir;
          };
        };

        services.pangolin = {
          enable = lib.mkDefault true;
          package = lib.mkDefault pkgs.custom.fosrl-pangolin;
          openFirewall = lib.mkDefault true;
          letsEncryptEmail = lib.mkDefault "letsencrypt.unpleased904@passmail.net";

          settings = {
            app.telemetry.enabled = false;
            server = lib.mkIf cfg.maxmindGeoip {
              maxmind_db_path = "${geoipDir}/GeoLite2-Country.mmdb";
            };
            flags = {
              disable_signup_without_invite = true;
              disable_user_create_org = true;
              enable_integration_api = true;
              allow_raw_resources = lib.mkDefault true;
            };
          };
        };

        services.traefik = {
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
            accessLog = lib.mkIf cfg.geoblock.enable {
              format = "json";
              filePath = "/var/log/traefik/access.log";
              fields.headers = {
                defaultMode = "drop";
                names.X-IPCountry = "keep";
              };
            };
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

        preservation.preserveAt."/persist".directories = [
          {
            directory = "/var/lib/pangolin";
            user = config.systemd.services.pangolin.serviceConfig.User;
            group = config.systemd.services.pangolin.serviceConfig.Group;
          }
        ]
        ++ lib.optional cfg.maxmindGeoip geoipDir;

        systemd.tmpfiles.rules = lib.mkIf cfg.geoblock.enable [
          "d /var/log/traefik 0755 traefik traefik -"
        ];

        systemd.services = {
          pangolin = {
            serviceConfig = {
              TimeoutStopSec = lib.mkDefault 10;
            };
            preStart = lib.mkAfter ''
              ${config.services.pangolin.package}/bin/pangolin-migrate || true
            '';
          };

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
    };
}
