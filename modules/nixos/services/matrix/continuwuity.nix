{
  flake.modules.nixos.matrix =
    {
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
        # nixos-unstable lags calver releases; drop back to pkgs.matrix-continuwuity once caught up
        package = pkgs.small.matrix-continuwuity;
        settings.global = {
          # apex delegates to ${publicHost} via /.well-known/matrix/server
          server_name = "fosskar.de";

          # all interfaces: reachable over netbird wt0; public via netbird-proxy on gateway
          address = [ "0.0.0.0" ];
          port = [ listenPort ];

          # closed: family accounts created via `!admin users create-user`
          allow_registration = false;
          registration_token_file = "/run/credentials/continuwuity.service/registration-token";

          new_user_displayname_suffix = "";

          allow_federation = true;

          # profile GET is unauthenticated by default; require auth to stop
          # display-name/avatar scraping of local users
          require_auth_for_profile_requests = true;

          # room for family photos/short videos; also caps incoming federated media
          max_request_size = 100000000;

          # online RocksDB backup target under already-offsite-backed /tank/backup.
          # run manually: `!admin server backup-database` in the admin room
          database_backup_path = "/tank/backup/continuwuity";
          database_backups_to_keep = 3;

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

      # required for the backup target: ProtectSystem=strict makes /tank read-only
      # to the service, and DynamicUser can't create the dir under it
      systemd.services.continuwuity.serviceConfig.ReadWritePaths = [ "/tank/backup/continuwuity" ];
      systemd.tmpfiles.rules = [ "d /tank/backup/continuwuity 0700 continuwuity continuwuity -" ];

      services.homepage-dashboard.services = [
        {
          "communication" = [
            {
              "Continuwuity" = {
                href = "https://${publicHost}";
                icon = "sh-continuwuity";
                siteMonitor = listenUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Continuwuity";
          url = "https://${publicHost}/_matrix/client/versions";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      # DynamicUser service: state lives in /var/lib/private/continuwuity,
      # covered by host-level /var/lib or /var/lib/private preservation.
    };
}
