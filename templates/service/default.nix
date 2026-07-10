{
  flake.modules.nixos.myservice =
    {
      flake-self,
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      serviceName = "myservice";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8000;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        clan.core.vars.generators.myservice = {
          files."secret.env" = { };

          runtimeInputs = [ pkgs.pwgen ];
          script = ''
            echo "SECRET_KEY=$(pwgen -s 64 1)" > "$out/secret.env"
          '';
        };

        services.myservice = {
          enable = true;
          # bind to ${listenAddress}:${toString listenPort}
        };

        systemd.services.myservice.serviceConfig.EnvironmentFile =
          config.clan.core.vars.generators.myservice.files."secret.env".path;

        services.homepage-dashboard.services = [
          {
            "<group>" = [
              {
                "MyService" = {
                  href = "https://${localHost}";
                  icon = "myservice.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        services.gatus.settings.endpoints = [
          {
            name = "MyService";
            url = "https://${localHost}";
            group = "<Group>";
            enabled = true;
            alerts = [ { type = "email"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          {
            directory = "/var/lib/myservice";
            user = "myservice";
            group = "myservice";
          }
        ];
      };
    };
}
