{
  flake.modules.nixos.gatus =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "gatus";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8700;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        services.gatus = {
          enable = true;
          settings = {
            web.port = listenPort;
            storage = {
              type = "sqlite";
              path = "/var/lib/gatus/gatus.db";
            };
            # same @alerts account and room as matrix-alert-hook (grafana);
            # the homeserver runs on this host, so talk to it directly
            alerting.matrix = {
              server-url = "http://127.0.0.1:6167";
              access-token = "$MX_TOKEN";
              internal-room-id = "!V9AbNBfBhczqH2WRQr_0wAT6q6ycq7tfSFuw9nM7t3s";
              default-alert = {
                enabled = true;
                failure-threshold = 5;
                success-threshold = 2;
                send-on-resolved = true;
              };
            };
          };
        };

        clan.core.state.gatus = {
          folders = [ "/var/backup/gatus" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/gatus
            sqlite3 /var/lib/gatus/gatus.db ".backup '/var/backup/gatus/gatus.db'"
          '';
        };

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';

        systemd.services.gatus.serviceConfig.EnvironmentFile =
          config.clan.core.vars.generators.matrix-alert-hook.files.env.path;

        services.homepage-dashboard.services = [
          {
            "monitoring" = [
              {
                "Gatus" = {
                  href = "https://${localHost}";
                  icon = "gatus.svg";
                  siteMonitor = listenUrl;
                  widget = {
                    type = "gatus";
                    url = listenUrl;
                    # homepage renders the fields as badges on the tile; the
                    # highlight level drives the badge color via data attribute
                    fields = [
                      "up"
                      "down"
                    ];
                    highlight.down.numeric = [
                      {
                        level = "danger";
                        when = "gt";
                        value = 0;
                      }
                    ];
                  };
                };
              }
            ];
          }
        ];
      };
    };
}
