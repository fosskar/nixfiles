{
  flake.modules.nixos.continuwuity =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "matrix";
      publicHost = "${serviceName}.${config.domains.public}";
      listenPort = 6167;
      listenUrl = "http://127.0.0.1:${toString listenPort}";
    in
    {
      clan.core.vars.generators.continuwuity = {
        files."registration-token" = { };
        runtimeInputs = [ pkgs.pwgen ];
        script = ''
          pwgen -s 48 1 | tr -d '\n' > "$out/registration-token"
        '';
      };

      services.matrix-continuwuity = {
        enable = true;
        settings.global = {
          # user ids are @user:fosskar.de; the apex delegates to ${publicHost}
          # via /.well-known/matrix/server served by continuwuity itself
          # (apex netbird peer target points at this instance too).
          server_name = "fosskar.de";

          # bind on all interfaces: reachable over netbird (wt0 is a
          # trusted interface); public exposure happens via the
          # netbird-proxy peer target for ${publicHost} on the gateway.
          address = [ "0.0.0.0" ];
          port = [ listenPort ];

          allow_registration = true;
          registration_token_file = "/run/credentials/continuwuity.service/registration-token";

          allow_federation = true;

          # no global ipv6 on this host; skip useless AAAA lookups
          ip_lookup_strategy = 1;

          # nixbox has ram to spare; larger caches speed up state
          # resolution and large room joins
          cache_capacity_modifier = 2.0;

          # served by continuwuity itself; keeps federation and clients on
          # :443 behind the netbird proxy without apex-domain delegation.
          well_known = {
            client = "https://${publicHost}";
            server = "${publicHost}:443";
          };
        };
      };

      systemd.services.continuwuity.serviceConfig.LoadCredential = [
        "registration-token:${
          config.clan.core.vars.generators.continuwuity.files."registration-token".path
        }"
      ];

      services.homepage-dashboard.serviceGroups."Communication" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "Continuwuity" = {
                href = "https://${publicHost}";
                icon = "matrix.svg";
                siteMonitor = listenUrl;
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "Continuwuity";
          url = "https://${publicHost}/_matrix/client/versions";
          group = "Communication";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "email"; } ];
        }
      ];

      # DynamicUser service: state lives in /var/lib/private/continuwuity,
      # covered by host-level /var/lib or /var/lib/private preservation.
    };
}
