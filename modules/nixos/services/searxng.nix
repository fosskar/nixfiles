{
  flake.modules.nixos.searxng =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "search";
      localHost = "${serviceName}.${config.domains.local}";
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

      services.homepage-dashboard.serviceGroups."Tools" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "SearXNG" = {
                href = "https://${localHost}";
                icon = "searxng.svg";
                siteMonitor = listenUrl;
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "SearXNG";
          url = "https://${localHost}";
          group = "Tools";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "email"; } ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}
