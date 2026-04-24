{
  flake.modules.nixos.vert =
    {
      config,
      lib,
      ...
    }:
    let
      acmeDomain = "nx3.eu";
      serviceDomain = "converter.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 8088;
      vertdPort = 8089;
      internalUrl = "http://${bindAddress}:${toString port}";
    in
    {
      config = {
        # --- service ---

        virtualisation.oci-containers.containers.vert = {
          image = "ghcr.io/vert-sh/vert:latest";
          ports = [ "127.0.0.1:${toString port}:80" ];
          environment = {
            PUB_VERTD_URL = "https://vertd.${acmeDomain}";
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
                  href = "https://${serviceDomain}";
                  icon = "mdi-video-switch";
                  siteMonitor = internalUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Vert";
            url = "https://${serviceDomain}";
            group = "Tools";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts."converter.nx3.eu".extraConfig = ''
          reverse_proxy 127.0.0.1:${toString port}
        '';
        services.caddy.virtualHosts."vertd.nx3.eu".extraConfig = ''
          reverse_proxy 127.0.0.1:${toString vertdPort}
        '';
      };
    };
}
