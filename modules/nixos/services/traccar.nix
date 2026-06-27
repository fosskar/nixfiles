{
  flake.modules.nixos.traccar =
    {
      flake-self,
      config,
      pkgs,
      ...
    }:
    let
      serviceName = "traccar";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 17191;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      oidcIssuerUrl = "https://auth.${flake-self.domains.public}";
    in
    {
      clan.core.vars.generators.traccar = {
        files."oauth-client-secret-hash" = {
          owner = "authelia-main";
          group = "authelia-main";
        };
        files."oidc-env" = { };
        runtimeInputs = [
          pkgs.pwgen
          pkgs.authelia
        ];
        script = ''
          SECRET=$(pwgen -s 64 1)
          authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
          {
            echo "TRACCAR_OIDC_CLIENT_SECRET=$SECRET"
            echo "TRACCAR_SERVICE_ACCOUNT_TOKEN=$(pwgen -s 64 1)"
          } > "$out/oidc-env"
        '';
      };

      services.authelia.instances.main.settings.identity_providers.oidc.claims_policies.traccar_groups.id_token =
        [ "groups" ];

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = "traccar";
          client_name = "Traccar";
          client_secret = "{{ secret \"${
            config.clan.core.vars.generators.traccar.files."oauth-client-secret-hash".path
          }\" }}";
          public = false;
          consent_mode = "implicit";
          authorization_policy = "users";
          claims_policy = "traccar_groups";
          redirect_uris = [ "https://${localHost}/api/session/openid/callback" ];
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];

      services.traccar = {
        enable = true;
        environmentFile = config.clan.core.vars.generators.traccar.files."oidc-env".path;
        settings = {
          web.address = listenAddress;
          web.port = toString listenPort;
          web.url = "https://${localHost}";

          protocols.enable = "osmand";
          # 5055 is osmand's default port but collides with seerr; move it
          osmand.port = "50556";

          openid.issuerUrl = oidcIssuerUrl;
          openid.clientId = "traccar";
          openid.clientSecret = "$TRACCAR_OIDC_CLIENT_SECRET";
          openid.force = "true";
          openid.allowRegistration = "true";
          openid.adminGroup = "admin";
          web.serviceAccountToken = "$TRACCAR_SERVICE_ACCOUNT_TOKEN";
        };
      };

      services.homepage-dashboard.services = [
        {
          "media" = [
            {
              "Traccar" = {
                href = "https://${localHost}";
                icon = "traccar.png";
                siteMonitor = listenUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Traccar";
          url = "https://${localHost}";
          group = "Media";
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
