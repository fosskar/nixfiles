{
  flake.modules.nixos.searxng =
    {
      flake-self,
      config,
      pkgs,
      ...
    }:
    let
      serviceName = "search";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8888;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      clan.core.vars.generators.searxng = {
        files."secret-key" = { };
        runtimeInputs = [ pkgs.openssl ];
        script = ''
          printf 'SEARXNG_SECRET_KEY=' > "$out/secret-key"
          openssl rand -hex 32 >> "$out/secret-key"
        '';
      };

      services.searx = {
        enable = true;
        redisCreateLocally = false;
        environmentFile = config.clan.core.vars.generators.searxng.files."secret-key".path;
        settings = {
          use_default_settings = true;
          server = {
            bind_address = listenAddress;
            port = listenPort;
            base_url = "https://${localHost}/";
            secret_key = "$SEARXNG_SECRET_KEY";
            limiter = false;
          };
          search.formats = [
            "html"
            "json"
          ];
        };
      };

      services.homepage-dashboard.serviceGroups."tools" = [
        {
          "SearXNG" = {
            href = "https://${localHost}";
            icon = "searxng.svg";
            siteMonitor = listenUrl;
          };
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "SearXNG";
          url = "https://${localHost}";
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
