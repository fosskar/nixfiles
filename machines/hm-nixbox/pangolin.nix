{
  config,
  ...
}:
{
  imports = [
    ../../modules/pangolin
  ];

  services = {
    geoipupdate.enable = false;

    pangolin = {
      baseDomain = "osscar.me";
      dashboardDomain = "pango.osscar.me";
      environmentFile = config.sops.secrets."pangolin.env".path;

      localOnly = true;

      # configure dns provider for dns-01 challenge
      # see: https://doc.traefik.io/traefik/https/acme/#providers
      dnsProvider = "cloudflare"; # change to your provider

      settings = {
        # enable wildcard certificates for automatic subdomain coverage
        domains.domain1 = {
          prefer_wildcard_cert = true;
        };
        traefik = {
          site_types = [ "local" ];
        };
      };
    };
    traefik.environmentFiles = [ config.sops.secrets."pangolin.env".path ];
  };

  systemd.services.traefik.environment = {
    TRAEFIK_EXPERIMENTAL_LOCALPLUGINS_BADGER_MODULENAME = "github.com/fosrl/badger";
  };
}
