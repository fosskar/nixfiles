{
  config,
  lib,
  ...
}:
{
  imports = [
    ../../modules/pangolin
  ];

  services = {
    pangolin = {
      baseDomain = "simonoscar.me";
      dashboardDomain = "pangolin.simonoscar.me";
      environmentFile = config.sops.secrets."hzc-pango.env".path;
      maxmindGeoip.enable = true;

      settings.flags.allow_raw_resources = true;

      geoblock = {
        enable = true;
        blacklistMode = true;
        blockedCountries = [
          "RU" # Russia
          "CN" # China
          "HK" # Hong Kong
          "IR" # Iran
          "KP" # North Korea
          "BY" # Belarus
          "BR" # Brazil
          "US" # USA
          "VN" # Vietnam
          "IN" # India
          "ID" # Indonesia
          "PK" # Pakistan
        ];
      };
    };
    traefik = {
      staticConfigOptions = {
        accessLog = {
          format = "json";
          filePath = "/var/log/traefik/access.log";
        };
        log.level = "WARN";
        api = {
          dashboard = true;
          insecure = false;
        };
        entryPoints.tcp-2222.address = ":2222/tcp";
        entryPoints.tcp-8428.address = ":8428/tcp"; # victoriametrics
        entryPoints.tcp-9428.address = ":9428/tcp"; # victoriamlogs
        entryPoints.metrics.address = ":8082";
        metrics.prometheus = {
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
        # crowdsec bouncer plugin
        experimental.plugins.crowdsec-bouncer = {
          moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
          version = "v1.3.5";
        };
        # apply crowdsec bouncer to all https traffic (mkForce to override module default)
        entryPoints.websecure.http.middlewares = lib.mkForce [
          "crowdsec@file"
          "geoblock@file"
        ];
      };
      dynamicConfigOptions.http.middlewares.crowdsec.plugin.crowdsec-bouncer = {
        crowdsecLapiKeyFile = "/var/lib/crowdsec/traefik-bouncer-api-key.cred";
        crowdsecLapiHost = "localhost:8080";
        crowdsecMode = "live";
        forwardedHeadersTrustedIPs = [
          "127.0.0.1/32"
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
        ];
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 2222 ];
}
