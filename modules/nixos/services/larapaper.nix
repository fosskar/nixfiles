{
  # self-hosted TRMNL server; trmnl.com refuses ICS urls that resolve to
  # private addresses, so calendars on nx3.eu need a server inside the lan
  flake.modules.nixos.larapaper =
    {
      flake-self,
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      serviceName = "trmnl";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 4567;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      dataDir = "/var/lib/larapaper";
    in
    {
      imports = [ flake-self.modules.nixos.podman ];

      config = {
        clan.core.vars.generators.larapaper = {
          files."secret.env" = { };
          runtimeInputs = [ pkgs.openssl ];
          script = ''
            echo "APP_KEY=base64:$(openssl rand -base64 32)" > "$out/secret.env"
          '';
        };

        systemd.tmpfiles.rules = [
          "d ${dataDir}/database 0750 root root -"
          "d ${dataDir}/images 0750 root root -"
        ];

        virtualisation.oci-containers = {
          backend = "podman";
          containers.larapaper = {
            image = "ghcr.io/usetrmnl/larapaper:0.44.0@sha256:d9d164ce98e48c71a7f62c05f5d288d7500720e485b69c2d16e368dc5292c406";
            ports = [ "${listenAddress}:${toString listenPort}:8080" ];
            environment = {
              APP_URL = "https://${localHost}";
              # only caddy on loopback reaches the published port
              TRUSTED_PROXIES = "*";
              DB_DATABASE = "database/storage/database.sqlite";
              PHP_OPCACHE_ENABLE = "1";
            };
            environmentFiles = [ config.clan.core.vars.generators.larapaper.files."secret.env".path ];
            # :U chowns the host dirs to the image's www-data (uid 82)
            volumes = [
              "${dataDir}/database:/var/www/html/database/storage:U"
              "${dataDir}/images:/var/www/html/storage/app/public/images/generated:U"
            ];
          };
        };

        services.homepage-dashboard.services = [
          {
            "tools" = [
              {
                "TRMNL" = {
                  href = "https://${localHost}";
                  icon = "sh-trmnl";
                  siteMonitor = "${listenUrl}/up";
                };
              }
            ];
          }
        ];

        services.gatus.settings.endpoints = [
          {
            name = "TRMNL";
            url = "https://${localHost}/up";
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [ dataDir ];
      };
    };
}
