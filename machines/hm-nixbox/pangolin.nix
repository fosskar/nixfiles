{
  config,
  lib,
  pkgs,
  ...
}:
let
  geolite2-country-db = pkgs.runCommand "geolite2-country" { } ''
    mkdir -p $out
    tar -xzf ${
      pkgs.fetchurl {
        url = "https://github.com/GitSquared/node-geolite2-redist/raw/refs/heads/master/redist/GeoLite2-Country.tar.gz";
        hash = "sha256-W2dnMqkdS1AGaSbxwEmLlZlktXYqslyFNvkBntqEthA=";
      }
    } -C $out --strip-components=1
  '';
in
{
  imports = [
    ../../modules/pangolin
  ];

  services.pangolin = {
    package = pkgs.callPackage ../../packages/fosrl-pangolin { };

    baseDomain = "osscar.me";
    dashboardDomain = "pango.osscar.me";
    environmentFile = config.sops.secrets."pangolin.env".path;

    # configure dns provider for dns-01 challenge
    # see: https://doc.traefik.io/traefik/https/acme/#providers
    dnsProvider = "cloudflare"; # change to your provider

    settings = {
      server = {
        maxmind_db_path = "${geolite2-country-db}/GeoLite2-Country.mmdb";
      };
      flags = {
        disable_signup_without_invite = true;
        enable_integration_api = true;
      };
      # enable wildcard certificates for automatic subdomain coverage
      domains.domain1 = {
        prefer_wildcard_cert = true;
      };
      traefik = {
        site_types = [ "local" ];
      };
    };
  };

  # disable gerbil service for local deployment (wireguard conflicts)
  systemd.services.gerbil.enable = false;

  # override traefik service dependencies to work without gerbil
  systemd.services.traefik = {
    environment = {
      TRAEFIK_EXPERIMENTAL_LOCALPLUGINS_BADGER_MODULENAME = "github.com/fosrl/badger";
    };
    # remove gerbil from requirements
    requires = lib.mkForce [ "network.target" ];
    after = lib.mkForce [
      "network.target"
      "pangolin.service"
    ];
    # ensure traefik wants pangolin but doesn't require it
    wants = [ "pangolin.service" ];
  };

  # ensure traefik service gets dns provider credentials
  services.traefik.environmentFiles = [ config.sops.secrets."pangolin.env".path ];
}
