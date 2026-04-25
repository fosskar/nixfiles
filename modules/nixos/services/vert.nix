{
  flake.modules.nixos.vert =
    {
      config,
      lib,
      ...
    }:
    let
      serviceName = "converter";
      localHost = "${serviceName}.${config.domains.local}";
      vertdHost = "vertd.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8088;
      vertdPort = 8089;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        # --- service ---

        virtualisation.oci-containers.containers.vert = {
          image = "ghcr.io/vert-sh/vert:latest";
          ports = [ "127.0.0.1:${toString listenPort}:80" ];
          environment = {
            PUB_VERTD_URL = "https://${vertdHost}";
          };
        };

        virtualisation.oci-containers.containers.vertd = {
          image = "ghcr.io/vert-sh/vertd:latest";
          ports = [ "127.0.0.1:${toString vertdPort}:24153" ];
          # gpu passthrough for vaapi
          extraOptions = [
            "--device=/dev/dri/card1"
            "--device=/dev/dri/renderD128"
          ];
        };

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."Tools" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Vert" = {
                  href = "https://${localHost}";
                  icon = "mdi-video-switch";
                  siteMonitor = listenUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Vert";
            url = "https://${localHost}";
            group = "Tools";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';
        services.caddy.virtualHosts.${vertdHost}.extraConfig = ''
          reverse_proxy 127.0.0.1:${toString vertdPort}
        '';
      };
    };
}
