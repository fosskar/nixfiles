{
  config,
  ...
}:
{
  imports = [
    ../../modules/pangolin
  ];

  services.pangolin = {
    baseDomain = "simonoscar.me";
    dashboardDomain = "pangolin.simonoscar.me";
    environmentFile = config.sops.secrets."hzc-pango.env".path;
  };
}
