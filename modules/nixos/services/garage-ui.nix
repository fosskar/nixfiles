# garage-ui web ui + its deployment glue (authelia oidc, homepage, gatus, caddy).
# co-locate with a garage node: reads the region from `services.garage` and
# takes the admin token via `adminTokenFile`.
{
  flake.modules.nixos.garageUi =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.garageUi;
      settingsFormat = pkgs.formats.yaml { };
      configFile = settingsFormat.generate "garage-ui.yaml" cfg.settings;

      serviceName = "s3";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 3909;
      listenUrl = "http://${listenAddress}:${toString listenPort}";

      uiVars = config.clan.core.vars.generators.garage-ui;
    in
    {
      options.services.garageUi = {
        enable = lib.mkEnableOption "the garage-ui web interface";

        package = lib.mkPackageOption pkgs [ "local" "garage-ui" ] { };

        settings = lib.mkOption {
          type = lib.types.submodule { freeformType = settingsFormat.type; };
          default = { };
          description = ''
            Configuration rendered to garage-ui's YAML config file and passed via
            `--config`. Sensible defaults for the local deployment are set
            automatically; override or extend as needed.
          '';
        };

        adminTokenFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to a file containing the garage admin token.";
        };
      };

      config = lib.mkIf cfg.enable {
        services.garageUi.settings = {
          server = {
            host = lib.mkDefault listenAddress;
            port = lib.mkDefault listenPort;
            environment = lib.mkDefault "production";
            root_url = lib.mkDefault "https://${localHost}";
          };
          garage = {
            endpoint = lib.mkDefault "http://localhost:3900";
            admin_endpoint = lib.mkDefault "http://localhost:3903";
            region = lib.mkDefault config.services.garage.settings.s3_api.s3_region;
          };
          auth.oidc = {
            enabled = lib.mkDefault true;
            provider_name = lib.mkDefault "Authelia";
            client_id = lib.mkDefault "garage-ui";
            issuer_url = lib.mkDefault "https://auth.${flake-self.domains.public}";
            scopes = lib.mkDefault [
              "openid"
              "email"
              "profile"
              "groups"
            ];
            role_attribute_path = lib.mkDefault "groups";
            admin_role = lib.mkDefault "admin";
            cookie_secure = lib.mkDefault true;
          };
        };

        systemd.services.garage-ui = {
          description = "Garage web UI";
          documentation = [ "https://github.com/khairul169/garage-webui" ];
          after = [
            "network-online.target"
            "garage.service"
          ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];

          environment = {
            GARAGE_UI_GARAGE_ADMIN_TOKEN_FILE = "%d/admin_token";
            GARAGE_UI_AUTH_OIDC_CLIENT_SECRET_FILE = "%d/oidc_client_secret";
            GARAGE_UI_AUTH_JWT_PRIVATE_KEY_FILE = "%d/jwt_key";
          };

          serviceConfig = {
            ExecStart = "${lib.getExe cfg.package} --config ${configFile}";
            Restart = "on-failure";
            RestartSec = 5;

            LoadCredential = [
              "admin_token:${cfg.adminTokenFile}"
              "oidc_client_secret:${uiVars.files."oauth-client-secret".path}"
              "jwt_key:${uiVars.files."jwt-private-key".path}"
            ];

            # hardening
            DynamicUser = true;
            CapabilityBoundingSet = "";
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectProc = "invisible";
            ProcSubset = "pid";
            ProtectSystem = "strict";
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [
              "@system-service"
              "~@privileged"
            ];
            UMask = "0077";
          };
        };

        # jwt-private-key is stable so sessions survive restarts.
        clan.core.vars.generators.garage-ui = {
          files."oauth-client-secret" = { };
          files."oauth-client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };
          files."jwt-private-key" = { };

          runtimeInputs = [
            pkgs.pwgen
            pkgs.openssl
            pkgs.authelia
          ];
          script = ''
            SECRET=$(pwgen -s 64 1)
            authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
            echo -n "$SECRET" > "$out/oauth-client-secret"
            openssl genpkey -algorithm ED25519 -out "$out/jwt-private-key"
          '';
        };

        services.homepage-dashboard.services = [
          {
            "infrastructure" = [
              {
                "Garage" = {
                  href = "https://${localHost}";
                  icon = "garage.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        services.gatus.settings.endpoints = [
          {
            name = "Garage";
            url = "https://${localHost}";
            enabled = true;
            alerts = [ { type = "email"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        # garage-ui handles its own OIDC login, so no caddy forward-auth here.
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';

        # garage-ui maps the groups claim to its admin role.
        services.authelia.instances.main.settings.identity_providers.oidc.claims_policies.garage_ui_groups.id_token =
          [ "groups" ];

        services.authelia.instances.main.settings.identity_providers.oidc.clients = [
          {
            client_id = "garage-ui";
            client_name = "Garage";
            client_secret = "{{ secret \"${uiVars.files."oauth-client-secret-hash".path}\" }}";
            public = false;
            consent_mode = "implicit";
            authorization_policy = "admins";
            redirect_uris = [ "https://${localHost}/auth/oidc/callback" ];
            scopes = [
              "openid"
              "email"
              "profile"
              "groups"
            ];
            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];
            token_endpoint_auth_method = "client_secret_basic";
            id_token_signed_response_alg = "RS256";
            claims_policy = "garage_ui_groups";
          }
        ];
      };
    };
}
