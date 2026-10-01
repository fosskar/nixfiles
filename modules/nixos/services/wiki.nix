{
  flake.modules.nixos.wiki =
    {
      flake-self,
      inputs,
      pkgs,
      ...
    }:
    let
      port = 8086;
      localHost = "fosskar.${flake-self.domains.local}";
    in
    {
      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';

      services.static-web-server = {
        enable = true;
        listen = "127.0.0.1:${toString port}";
        root = inputs.wiki.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };

      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              "fosskar's bliki" = {
                href = "https://${localHost}/";
                icon = "https://${localHost}/icon.svg";
                siteMonitor = "https://${localHost}/";
              };
            }
          ];
        }
      ];

      services.anubis.instances.bliki.settings = {
        TARGET = "http://127.0.0.1:${toString port}";
        BIND = "0.0.0.0:8098";
        BIND_NETWORK = "tcp";
        METRICS_BIND = "127.0.0.1:8099";
        METRICS_BIND_NETWORK = "tcp";
      };
    };
}
