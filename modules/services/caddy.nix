{
  flake.modules.nixos.caddy =
    {
      config,
      pkgs,
      ...
    }:
    {
      clan.core.vars.generators.caddy = {
        prompts."desec_token" = {
          description = "deSEC API token for ACME dns-01 challenge";
          type = "hidden";
          persist = true;
        };
        files."envfile" = { };
        script = ''
          echo "DESEC_TOKEN=$(cat "$prompts/desec_token")" > "$out/envfile"
        '';
      };

      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/desec@v1.1.0" ];
          hash = "sha256-4sP/IVuUhbTu+4Z5kBttVBdP7cXtHDavp8DChv1bwjQ=";
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
        virtualHosts."*.nx3.eu".extraConfig = "";
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

      preservation.preserveAt."/persist".directories = [
        {
          directory = "/var/lib/caddy";
          user = "caddy";
          group = "caddy";
        }
      ];
    };
}
