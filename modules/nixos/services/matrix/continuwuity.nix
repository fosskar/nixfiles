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

      # separate generator: extending the continuwuity generator would
      # invalidate and rotate the existing registration-token
      clan.core.vars.generators.continuwuity-oidc = {
        files."oauth-client-secret" = { };
        files."oauth-client-secret-hash" = {
          owner = "authelia-main";
          group = "authelia-main";
        };
        runtimeInputs = [
          pkgs.pwgen
          pkgs.authelia
        ];
        script = ''
          SECRET=$(pwgen -s 64 1)
          echo -n "$SECRET" > "$out/oauth-client-secret"
          authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
        '';
      };

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = "continuwuity";
          client_name = "Continuwuity";
          client_secret = "{{ secret \"${
            config.clan.core.vars.generators.continuwuity-oidc.files."oauth-client-secret-hash".path
          }\" }}";
          public = false;
          consent_mode = "implicit";
          authorization_policy = "users";
          # continuwuity always sends an S256 PKCE challenge (oidc/mod.rs begin_session)
          require_pkce = true;
          pkce_challenge_method = "S256";
          # redirect target: get_client_domain() (= well_known.client) + ROUTE_PREFIX/oidc/complete
          redirect_uris = [ "https://${publicHost}/_continuwuity/oidc/complete" ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          # openidconnect-rs default
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];

      services.matrix-continuwuity = {
        enable = true;
        # nixos-unstable lags calver releases; drop back to pkgs.matrix-continuwuity once caught up.
        # patch: upstream forces oauth-exclusive when oidc is set, breaking password
        # login for non-OAuth clients (Grid); hybrid keeps both auth paths
        package = pkgs.small.matrix-continuwuity.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./oauth-hybrid.patch ];
        });
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

          # delegated auth via authelia. oauth-hybrid.patch makes this mode
          # effective with oidc set (upstream would force exclusive): oidc
          # clients use delegated auth, password clients (Grid) use UIA.
          # default prompt_for_localpart = true stays on purpose so family
          # links existing accounts by confirming the matrix password once.
          oauth.compatibility_mode = "hybrid";
          oauth.oidc = {
            discovery_url = "https://auth.${flake-self.domains.public}";
            client_id = "continuwuity";
            client_secret_file = "/run/credentials/continuwuity.service/oauth-client-secret";
            # profile: displayname import (profile_key_map default) + preferred_username
            additional_scopes = [
              "profile"
              "email"
            ];
          };
        };
      };

      systemd.services.continuwuity.serviceConfig.LoadCredential = [
        "registration-token:${
          config.clan.core.vars.generators.continuwuity.files."registration-token".path
        }"
        "oauth-client-secret:${
          config.clan.core.vars.generators.continuwuity-oidc.files."oauth-client-secret".path
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
