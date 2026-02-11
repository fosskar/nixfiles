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
      baseDomain = "fosskar.eu";
      dashboardDomain = "pangolin.fosskar.eu";
      environmentFile = config.sops.secrets."hzc-pango.env".path;
      maxmindGeoip.enable = true;
      crowdsec.enable = true;

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
    # machine-specific traefik entrypoints for raw resources
    traefik.static.settings = {
      entryPoints.tcp-8428.address = ":8428/tcp"; # victoriametrics
      entryPoints.tcp-9428.address = ":9428/tcp"; # victorialogs
    };
  };
}
