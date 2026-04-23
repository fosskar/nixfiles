{
  flake.modules.nixos.acme =
    { config, lib, ... }:
    let
      domain = "nx3.eu";
    in
    {
      security.acme = {
        acceptTerms = true;
        defaults.email = "letsencrypt.unpleased904@passmail.net";
        certs.${domain} = {
          domain = "*.${domain}";
          extraDomainNames = [ domain ];
          dnsProvider = "cloudflare";
          environmentFile = config.clan.core.vars.generators.acme-dns-01.files.envfile.path;
          inherit (config.services.nginx) group;
        };
      };

      services.nginx = {
        enable = true;
        statusPage = lib.mkDefault true;
        recommendedBrotliSettings = lib.mkDefault true;
        recommendedGzipSettings = lib.mkDefault true;
        recommendedOptimisation = lib.mkDefault true;
        recommendedProxySettings = lib.mkDefault true;
        recommendedTlsSettings = lib.mkDefault true;

        commonHttpConfig = "access_log syslog:server=unix:/dev/log;";
      };

      clan.core.vars.generators.prompt_acme_api_key = {
        prompts."acme_api_key" = {
          description = "cloudflare API token for ACME dns-01 challenge";
          persist = true;
        };
      };

      clan.core.vars.generators.acme-dns-01 = {
        files.envfile = {
          owner = config.services.nginx.user;
          inherit (config.services.nginx) group;
        };
        dependencies = [ "prompt_acme_api_key" ];
        script = ''
          APITOKEN=$(cat $in/prompt_acme_api_key/acme_api_key)
          echo "CF_DNS_API_TOKEN=$APITOKEN" > $out/envfile
        '';
      };
    };
}
