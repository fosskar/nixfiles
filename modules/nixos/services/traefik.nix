# shared traefik reverse proxy base
# provides: entrypoints, acme, access log, metrics, geoblock middleware, persistence
# other modules add routes/services/middlewares via services.traefik merging
{
  flake.modules.nixos.traefik =
    { config, lib, ... }:
    let
      acmeEmail = "letsencrypt.unpleased904@passmail.net";
      metricsAddress = "127.0.0.1:8082";
    in
    {
      config = {
        services.traefik = {
          enable = true;

          staticConfigOptions = {
            log.level = lib.mkDefault "WARN";

            entryPoints = {
              web = {
                address = ":80";
                http.redirections.entryPoint = {
                  to = "websecure";
                  scheme = "https";
                };
              };
              websecure = {
                address = ":443";
                http3 = { };
              };
              metrics.address = metricsAddress;
            };

            certificatesResolvers.letsencrypt.acme = {
              email = acmeEmail;
              storage = "/var/lib/traefik/acme.json";
              tlsChallenge = { };
            };

            metrics.prometheus = {
              entryPoint = "metrics";
              buckets = [
                0.1
                0.3
                1.2
                5.0
              ];
              addEntryPointsLabels = true;
              addRoutersLabels = true;
              addServicesLabels = true;
            };

            accessLog = {
              filePath = "/var/log/traefik/access.log";
              format = "json";
            };
          };
        };

        services.telegraf.extraConfig.inputs.prometheus = lib.mkIf config.services.telegraf.enable [
          {
            urls = [ "http://${metricsAddress}/metrics" ];
          }
        ];

        preservation.preserveAt."/persist".directories = [
          {
            directory = "/var/lib/traefik";
            user = "traefik";
            group = "traefik";
          }
        ];

        systemd.services.traefik.serviceConfig.StateDirectory = "traefik";

        systemd.tmpfiles.rules = [
          "d /var/log/traefik 0755 traefik traefik -"
        ];

        networking.firewall = {
          allowedTCPPorts = [
            80
            443
          ];
          allowedUDPPorts = [
            443 # HTTP/3 (QUIC)
          ];
        };
      };
    };
}
