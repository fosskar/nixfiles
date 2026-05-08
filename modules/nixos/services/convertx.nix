{
  flake.modules.nixos.convertx =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "converter";
      localHost = "${serviceName}.${config.domains.local}";
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

      services.homepage-dashboard.serviceGroups."Tools" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "ConvertX" = {
                href = "https://${localHost}";
                icon = "mdi-file-sync";
                siteMonitor = healthUrl;
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "ConvertX";
          url = "https://${localHost}/healthcheck";
          group = "Tools";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}
