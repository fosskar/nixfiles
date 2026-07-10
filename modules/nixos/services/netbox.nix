{
  flake.modules.nixos.netbox =
    {
      flake-self,
      config,
      pkgs,
      ...
    }:
    let
      serviceName = "netbox";
      localHost = "${serviceName}.${flake-self.domains.local}";
      oidcIssuerUrl = "https://auth.${flake-self.domains.public}";
      listenAddress = "127.0.0.1";
      listenPort = 8001;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      clan.core.vars.generators.netbox = {
        files = {
          "secret-key" = {
            owner = "netbox";
            group = "netbox";
          };
          "api-token-pepper" = {
            owner = "netbox";
            group = "netbox";
          };
          "oauth-client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };
          "oauth-client-secret" = {
            owner = "netbox";
            group = "netbox";
          };
        };
        runtimeInputs = [
          pkgs.authelia
          pkgs.pwgen
        ];
        script = ''
          pwgen -s 64 1 | tr -d '\n' > "$out/secret-key"
          pwgen -s 64 1 | tr -d '\n' > "$out/api-token-pepper"

          SECRET=$(pwgen -s 64 1)
          authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
          echo -n "$SECRET" > "$out/oauth-client-secret"
        '';
      };

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = serviceName;
          client_name = "NetBox";
          client_secret = "{{ secret \"${
            config.clan.core.vars.generators.netbox.files."oauth-client-secret-hash".path
          }\" }}";
          public = false;
          consent_mode = "implicit";
          authorization_policy = "users";
          redirect_uris = [ "https://${localHost}/oauth/complete/oidc/" ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];

      services.netbox = {
        enable = true;
        inherit listenAddress;
        port = listenPort;
        secretKeyFile = config.clan.core.vars.generators.netbox.files."secret-key".path;
        apiTokenPeppersFile = config.clan.core.vars.generators.netbox.files."api-token-pepper".path;
        settings = {
          ALLOWED_HOSTS = [ localHost ];
          REMOTE_AUTH_ENABLED = true;
          REMOTE_AUTH_AUTO_CREATE_USER = true;
          REMOTE_AUTH_BACKEND = "social_core.backends.open_id_connect.OpenIdConnectAuth";
          SOCIAL_AUTH_OIDC_KEY = serviceName;
          SOCIAL_AUTH_OIDC_OIDC_ENDPOINT = oidcIssuerUrl;
          SOCIAL_AUTH_BACKEND_ATTRS.oidc = [
            "Authelia"
            "login"
          ];
        };
        extraConfig = ''
          with open("${
            config.clan.core.vars.generators.netbox.files."oauth-client-secret".path
          }", "r") as file:
              SOCIAL_AUTH_OIDC_SECRET = file.readline()
        '';
      };

      systemd.services.caddy.serviceConfig.SupplementaryGroups = [ "netbox" ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        handle /static/* {
          root * ${config.services.netbox.dataDir}
          file_server
        }

        handle /media/* {
          root * ${config.services.netbox.dataDir}
          file_server
        }

        reverse_proxy ${listenUrl}
      '';

      services.homepage-dashboard.services = [
        {
          "infrastructure" = [
            {
              "NetBox" = {
                href = "https://${localHost}";
                icon = "netbox.svg";
                siteMonitor = listenUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "NetBox";
          url = "https://${localHost}";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];
    };
}
