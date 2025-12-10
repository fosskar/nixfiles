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
      geoblock = {
        enable = true;
        allowedCountries = [ "DE" ];
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
      };
    };
  };
}
