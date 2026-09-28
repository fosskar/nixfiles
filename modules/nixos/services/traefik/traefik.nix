# shared traefik base (entrypoints, acme, logs, geoblock); other modules merge in routes
{
  flake.modules.nixos.traefik =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      acmeEmail = "letsencrypt.unpleased904@passmail.net";
      metricsAddress = "127.0.0.1:8082";
    in
    {
      options.nixfiles.traefik.localPlugins = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
        default = { };
        description = "plugin sources by module name, loaded via experimental.localPlugins";
      };

      config = {
        # traefik reads plugins-local/src/<module> relative to its working
        # directory; a store tree needs no runtime setup in the traefik-owned
        # state dir, where tmpfiles refuses root-owned paths
        systemd.services.traefik.serviceConfig.WorkingDirectory =
          lib.mkIf (config.nixfiles.traefik.localPlugins != { })
            (
              lib.mkForce (
                pkgs.linkFarm "traefik-local-plugins" (
                  lib.mapAttrsToList (moduleName: src: {
                    name = "plugins-local/src/${moduleName}";
                    path = src;
                  }) config.nixfiles.traefik.localPlugins
                )
              )
            );

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
                http = {
                  middlewares = lib.optionals config.services.crowdsec.enable [ "crowdsec@file" ] ++ [
                    "geoblock@file"
                  ];
                };
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

        systemd.services.traefik.serviceConfig.StateDirectory = "traefik";

        # traefik reopens access.log on USR1; crowdsec file acquisition follows rotation
        services.logrotate.settings."/var/log/traefik/access.log" = {
          frequency = "daily";
          rotate = 7;
          compress = true;
          delaycompress = true;
          missingok = true;
          notifempty = true;
          su = "traefik traefik";
          postrotate = "systemctl kill --signal=USR1 traefik.service";
        };

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
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          {
            directory = "/var/lib/traefik";
            user = "traefik";
            group = "traefik";
          }
        ];
      };
    };
}
