{
  config,
  ...
}:
{
  imports = [
    ../../modules/pangolin
  ];

  environment.persistence."/persist".directories = [
    {
      directory = "/var/lib/pangolin";
      user = "pangolin";
      group = "fossorial";
      mode = "0755";
    }
  ];

  services.pangolin = {
    baseDomain = "simonoscar.me";
    dashboardDomain = "pangolin.simonoscar.me";
    environmentFile = config.age.secrets.envs-hzx.path;

    # add additional domains beyond the base domain
    #settings.domains = {
    # baseDomain is automatically added, add more here:
    # "example.com" = {
    #   base_domain = "example.com";
    #   cert_resolver = "letsencrypt";
    #   prefer_wildcard_cert = true;
    # };
    # "another.org" = {
    #   base_domain = "another.org";
    #   cert_resolver = "letsencrypt";
    #   prefer_wildcard_cert = false;
    # };
    #};
  };
}
