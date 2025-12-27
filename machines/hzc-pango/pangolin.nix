{
  config,
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
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 2222 ];
}
