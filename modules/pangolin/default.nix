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
        };
      };
    };

    # traefik geoblock plugin configuration
    services.traefik = lib.mkIf cfg.geoblock.enable {
      staticConfigOptions = {
        experimental.plugins.geoblock = {
          moduleName = "github.com/PascalMinder/geoblock";
          version = "v0.3.2";
        };
        entryPoints.websecure.http.middlewares = [ "geoblock@file" ];
      };
      dynamicConfigOptions = {
        http.middlewares.geoblock.plugin.geoblock = {
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
        };
      };
    };

    systemd.services = {
      # reduce shutdown timeout for faster reboots
      # pangolin doesn't gracefully close websocket tunnels on SIGTERM
      pangolin = {
        serviceConfig = {
          TimeoutStopSec = lib.mkDefault 10;
          KillMode = lib.mkDefault "mixed"; # send SIGTERM to main process, then SIGKILL to all
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
