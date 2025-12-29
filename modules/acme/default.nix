{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.acme;
in
{
  options.nixfiles.acme = {
    enable = lib.mkEnableOption "acme wildcard certs";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "osscar.me";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "letsencrypt.unpleased904@passmail.net";
    };
    dnsProvider = lib.mkOption {
      type = lib.types.str;
      default = "cloudflare";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      security.acme = {
        acceptTerms = true;
        defaults.email = cfg.email;
        certs.${cfg.domain} = {
          domain = "*.${cfg.domain}";
          extraDomainNames = [ cfg.domain ];
          inherit (cfg) dnsProvider;
          environmentFile = config.clan.core.vars.generators.acme-dns-01.files.envfile.path;
          inherit (config.services.nginx) group;
        };
      };

      services.nginx = {
        enable = true;
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;
        recommendedProxySettings = true;
      };
    })

    # cloudflare dns provider config
    (lib.mkIf (cfg.enable && cfg.dnsProvider == "cloudflare") {
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
    })
  ];
}
