{
  flake.modules.nixos.acme =
    { config, lib, ... }:
    {
      options.nixfiles.acme = {
        domain = lib.mkOption {
          type = lib.types.str;
          default = "nx3.eu";
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

      config =
        let
          cfg = config.nixfiles.acme;
        in
        lib.mkMerge [
          {
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
              statusPage = lib.mkDefault true;
              recommendedBrotliSettings = lib.mkDefault true;
              recommendedGzipSettings = lib.mkDefault true;
              recommendedOptimisation = lib.mkDefault true;
              recommendedProxySettings = lib.mkDefault true;
              recommendedTlsSettings = lib.mkDefault true;

              commonHttpConfig = "access_log syslog:server=unix:/dev/log;";
            };
          }

          (lib.mkIf (cfg.dnsProvider == "cloudflare") {
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
    };
}
