{
  flake.modules.nixos.convertx =
    {
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "converter";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 3000;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      healthUrl = "${listenUrl}/healthcheck";
    in
    {
      users.groups.convertx = { };
      users.users.convertx = {
        isSystemUser = true;
        group = "convertx";
        home = "/var/lib/convertx";
      };

      systemd.services.convertx = {
        description = "ConvertX file converter";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          ALLOW_UNAUTHENTICATED = "true";
          HIDE_HISTORY = "true";
        };
        serviceConfig = {
          ExecStart = lib.getExe pkgs.convertx;
          Group = "convertx";
          Restart = "on-failure";
          StateDirectory = "convertx";
          StateDirectoryMode = "0750";
          User = "convertx";
          WorkingDirectory = "/var/lib/convertx";
        };
      };

      services.homepage-dashboard.serviceGroups."tools" = [
        {
          "ConvertX" = {
            href = "https://${localHost}";
            icon = "mdi-file-sync";
            siteMonitor = healthUrl;
          };
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "ConvertX";
          url = "https://${localHost}/healthcheck";
          group = "Tools";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}
