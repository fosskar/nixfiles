{
  flake.modules.nixos.website =
    {
      flake-self,
      inputs,
      pkgs,
      ...
    }:
    let
      port = 8086;
      localHost = "fosskar.${flake-self.domains.local}";
      publicHost = "simon.${flake-self.domains.public}";
    in
    {
      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';

      services.static-web-server = {
        enable = true;
        listen = "127.0.0.1:${toString port}";
        root = inputs.website.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };

      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              "fosskar" = {
                href = "https://${localHost}/";
                icon = "https://${localHost}/icon.png";
                siteMonitor = "https://${localHost}/";
              };
            }
          ];
        }
      ];

      services.anubis.instances.website.settings = {
        TARGET = "http://127.0.0.1:${toString port}";
        BIND = "0.0.0.0:8098";
        BIND_NETWORK = "tcp";
        METRICS_BIND = "127.0.0.1:8099";
        METRICS_BIND_NETWORK = "tcp";
        # bliki stays until its netbird mapping is removed
        REDIRECT_DOMAINS = "${publicHost},bliki.${flake-self.domains.public}";
        OG_PASSTHROUGH = true;
      };
    };
}
