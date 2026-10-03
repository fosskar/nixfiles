{
  flake.modules.nixos.yuvomi =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "yuvomi";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 3030;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      dataDir = "/tank/apps/yuvomi";
      generators = config.clan.core.vars.generators;
    in
    {
      # the database key lives in its own generator so regenerating the other
      # secrets can never replace it; a changed key locks the database
      clan.core.vars.generators.yuvomi-db-key = {
        files.envfile.restartUnits = [ "yuvomi.service" ];
        runtimeInputs = [ pkgs.pwgen ];
        script = ''
          echo "DB_ENCRYPTION_KEY=$(pwgen -s 64 1)" > "$out/envfile"
        '';
      };

      clan.core.vars.generators.yuvomi = {
        files = {
          envfile.restartUnits = [ "yuvomi.service" ];
          "oauth-client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };
        };
        runtimeInputs = [
          pkgs.pwgen
          pkgs.authelia
        ];
        script = ''
          OAUTH_SECRET=$(pwgen -s 64 1)
          authelia crypto hash generate pbkdf2 --password "$OAUTH_SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
          {
            echo "SESSION_SECRET=$(pwgen -s 64 1)"
            echo "OIDC_CLIENT_SECRET=$OAUTH_SECRET"
          } > "$out/envfile"
        '';
      };

      clan.core.vars.generators.yuvomi-smtp = {
        dependencies = [ "smtp" ];
        files.envfile.restartUnits = [ "yuvomi.service" ];
        script = ''
          {
            echo "EMAIL_SMTP_USER=$(cat "$in/smtp/username")"
            echo "EMAIL_SMTP_PASS=$(cat "$in/smtp/password")"
          } > "$out/envfile"
        '';
      };

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = serviceName;
          client_name = "Yuvomi";
          client_secret = "{{ secret \"${generators.yuvomi.files."oauth-client-secret-hash".path}\" }}";
          public = false;
          consent_mode = "implicit";
          authorization_policy = "users";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [ "https://${localHost}/api/v1/auth/oidc/callback" ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];

      users.users.yuvomi = {
        isSystemUser = true;
        group = "yuvomi";
        home = dataDir;
      };
      users.groups.yuvomi = { };

      systemd.tmpfiles.rules = [ "d ${dataDir} 0750 yuvomi yuvomi -" ];

      systemd.services.yuvomi = {
        description = "Yuvomi family planner";
        documentation = [ "https://github.com/ulsklyc/yuvomi" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.RequiresMountsFor = [ dataDir ];

        environment = {
          NODE_ENV = "production";
          PORT = toString listenPort;
          BIND_ADDRESS = listenAddress;
          BASE_URL = "https://${localHost}";
          SESSION_SECURE = "true";
          TZ = "Europe/Berlin";

          DB_PATH = "${dataDir}/yuvomi.db";
          BACKUP_DIR = "${dataDir}/backups";
          MODULES_DIR = "${dataDir}/modules";

          OIDC_ISSUER = "https://auth.${flake-self.domains.public}";
          OIDC_CLIENT_ID = serviceName;
          OIDC_REDIRECT_URI = "https://${localHost}/api/v1/auth/oidc/callback";

          EMAIL_SMTP_HOST = "smtp.mailbox.org";
          EMAIL_SMTP_PORT = "587";
          EMAIL_SMTP_SECURE = "starttls";
          EMAIL_FROM_ADDRESS = "noreply@${flake-self.domains.local}";
          EMAIL_FROM_NAME = "Yuvomi";
        };

        serviceConfig = {
          ExecStart = lib.getExe pkgs.local.yuvomi;
          WorkingDirectory = dataDir;
          EnvironmentFile = [
            generators.yuvomi-db-key.files.envfile.path
            generators.yuvomi.files.envfile.path
            generators.yuvomi-smtp.files.envfile.path
          ];
          User = "yuvomi";
          Group = "yuvomi";
          Restart = "on-failure";
          RestartSec = 5;

          # hardening; no MemoryDenyWriteExecute, v8 jit needs w+x pages
          ReadWritePaths = [ dataDir ];
          CapabilityBoundingSet = "";
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
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

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';

      services.homepage-dashboard.services = [
        {
          "apps" = [
            {
              "Yuvomi" = {
                href = "https://${localHost}";
                icon = "sh-yuvomi";
                siteMonitor = "${listenUrl}/health";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Yuvomi";
          url = "https://${localHost}/health";
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];
    };
}
