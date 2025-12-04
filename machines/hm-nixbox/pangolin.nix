{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/pangolin
  ];

  services = {
    pangolin = {
      baseDomain = "osscar.me";
      dashboardDomain = "pango.osscar.me";
      environmentFile = config.sops.secrets."pangolin.env".path;

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

  # disable gerbil service for local deployment (wireguard conflicts)
  systemd.services = {

    gerbil.enable = false;

    traefik = {
      environment = {
        TRAEFIK_EXPERIMENTAL_LOCALPLUGINS_BADGER_MODULENAME = "github.com/fosrl/badger";
      };
      requires = lib.mkForce [ "network.target" ];
      after = lib.mkForce [
        "network.target"
        "pangolin.service"
      ];
      wants = [ "pangolin.service" ];
    };
  };
}
