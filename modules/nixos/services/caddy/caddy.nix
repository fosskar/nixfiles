{
  flake.modules.nixos.caddy =
    {
      flake-self,
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    {
      config = {
        clan.core.vars.generators.caddy = {
          prompts."desec_token" = {
            description = "deSEC API token for ACME dns-01 challenge";
            persist = true;
          };
          files."envfile" = {
            owner = config.services.caddy.user;
            group = config.services.caddy.group;
          };
          script = ''
            echo "DESEC_TOKEN=$(cat "$prompts/desec_token")" > "$out/envfile"
          '';
        };

        services.caddy = {
          enable = true;
          package = pkgs.caddy.withPlugins {
            plugins = [ "github.com/caddy-dns/desec@v1.1.0" ];
            hash = "sha256-w80Yv8Bznxn1EuI+DGjLSIFhENDfWhLgvhdR0oI36A4=";
          };
          email = "letsencrypt.unpleased904@passmail.net";
          globalConfig = ''
            acme_dns desec {
              token {env.DESEC_TOKEN}
            }
          '';
          extraConfig = ''
            (authelia) {
              forward_auth 127.0.0.1:9091 {
                uri /api/authz/forward-auth
                copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
              }
            }
          '';
          virtualHosts."*.${flake-self.domains.local}".extraConfig = "";
        };

        networking.firewall = {
          allowedTCPPorts = [
            80
            443
          ];
          allowedUDPPorts = [
            443 # HTTP/3 (QUIC)
          ];
        };

        systemd.services.caddy.serviceConfig.EnvironmentFile =
          config.clan.core.vars.generators.caddy.files."envfile".path;
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          {
            directory = "/var/lib/caddy";
            user = "caddy";
            group = "caddy";
          }
        ];
      };
    };
}
