{
  flake.modules.nixos.continuwuity =
    {
      nflib,
      flake-self,
      config,
      pkgs,
      ...
    }:
    let
      serviceName = "matrix";
      publicHost = "${serviceName}.${flake-self.domains.public}";
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
          # apex delegates to ${publicHost} via /.well-known/matrix/server
          server_name = "fosskar.de";

          # all interfaces: reachable over netbird wt0; public via netbird-proxy on gateway
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

      services.homepage-dashboard.serviceGroups."communication" = [
        {
          "Continuwuity" = {
            href = "https://${publicHost}";
            icon = "matrix.svg";
            siteMonitor = listenUrl;
          };
        }
      ];

      services.gatus.settings.endpoints = [
        (nflib.gatusEndpoint {
          name = "Continuwuity";
          url = "https://${publicHost}/_matrix/client/versions";
          group = "Communication";
        })
      ];

      # DynamicUser service: state lives in /var/lib/private/continuwuity,
      # covered by host-level /var/lib or /var/lib/private preservation.
    };
}
