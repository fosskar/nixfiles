{
  flake.modules.nixos.netbirdServer = # netbird server (management + signal + relay + stun + embedded IdP)
    {
      config,
      lib,
      pkgs,
      options,
      ...
    }:

    let
      cfg = config.services.netbird.server;
      hasPreservation = lib.hasAttrByPath [ "nixfiles" "preservation" "directories" ] options;
      stateDir = "/var/lib/netbird-server";
      settingsFormat = pkgs.formats.yaml { };
      # config without secrets — secrets injected at runtime
      configFile = settingsFormat.generate "netbird-server.yaml" cfg.settings;
    in
    {
      # --- options ---

      options.services.netbird.server = {
        enable = lib.mkEnableOption "netbird server";

        package = lib.mkOption {
          type = lib.types.package;
          description = "netbird-server package";
        };

        domain = lib.mkOption {
          type = lib.types.str;
          description = "public domain for the netbird server";
          example = "nb.fosskar.eu";
        };

        authSecretFile = lib.mkOption {
          type = lib.types.path;
          description = "path to file containing relay auth secret";
        };

        encryptionKeyFile = lib.mkOption {
          type = lib.types.path;
          description = "path to file containing data store encryption key";
        };

        ownerEmail = lib.mkOption {
          type = lib.types.str;
          description = "owner email for embedded IdP";
          example = "admin@fosskar.eu";
        };

        ownerPasswordHashFile = lib.mkOption {
          type = lib.types.path;
          description = "path to file containing bcrypt hash of owner password";
        };

        settings = lib.mkOption {
          inherit (settingsFormat) type;
          default = { };
          description = "netbird server YAML config (secrets injected at runtime)";
        };

        logLevel = lib.mkOption {
          type = lib.types.enum [
            "panic"
            "fatal"
            "error"
            "warn"
            "info"
            "debug"
            "trace"
          ];
          default = "info";
        };
      };

      config = lib.mkIf cfg.enable {
        # --- service ---

        services.netbird.server.settings = {
          server = {
            listenAddress = lib.mkDefault "127.0.0.1:8081";
            exposedAddress = lib.mkDefault "https://${cfg.domain}:443";
            metricsPort = lib.mkDefault 9090;
            healthcheckAddress = lib.mkDefault "127.0.0.1:9000";
            logLevel = lib.mkDefault cfg.logLevel;
            logFile = lib.mkDefault "console";
            dataDir = lib.mkDefault stateDir;
            disableAnonymousMetrics = lib.mkDefault true;
            disableGeoliteUpdate = lib.mkDefault false;

            tls.letsencrypt = {
              enabled = lib.mkDefault false;
            };

            auth = {
              issuer = lib.mkDefault "https://${cfg.domain}/oauth2";
              dashboardRedirectURIs = lib.mkDefault [
                "https://${cfg.domain}/nb-auth"
                "https://${cfg.domain}/nb-silent-auth"
              ];
              cliRedirectURIs = lib.mkDefault [
                "http://localhost:53000/"
              ];
              # owner placeholder — replaced in preStart via envsubst
              owner = {
                email = cfg.ownerEmail;
                password = "$OWNER_HASH";
              };
            };

            store.engine = lib.mkDefault "sqlite";

            # secrets are placeholders — replaced in preStart via envsubst
            authSecret = "$AUTH_SECRET";
            store.encryptionKey = "$ENCRYPTION_KEY";
          };
        };

        users.users.netbird = {
          isSystemUser = true;
          group = "netbird";
        };
        users.groups.netbird = { };

        # STUN — netbird clients connect directly, not through traefik
        networking.firewall.allowedUDPPorts = [ 3478 ];

        # export netbird metrics via telegraf scrape endpoint
        services.telegraf.extraConfig.inputs.prometheus = lib.mkIf config.services.telegraf.enable [
          {
            urls = [ "http://127.0.0.1:${toString cfg.settings.server.metricsPort}/metrics" ];
          }
        ];

        # --- backup ---

        clan.core.state.netbird-server = {
          folders = [ "/var/backup/netbird-server" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/netbird-server
            sqlite3 /var/lib/netbird-server/store.db ".backup '/var/backup/netbird-server/store.db'"
            sqlite3 /var/lib/netbird-server/events.db ".backup '/var/backup/netbird-server/events.db'"
            sqlite3 /var/lib/netbird-server/idp.db ".backup '/var/backup/netbird-server/idp.db'"
          '';
        };

        # --- persistence ---

        nixfiles = lib.optionalAttrs hasPreservation {
          preservation.directories = [
            {
              directory = "/var/lib/netbird-server";
              user = "netbird";
              group = "netbird";
            }
          ];
        };

        # --- systemd ---

        systemd.services.netbird-server = {
          description = "netbird server (management + signal + relay)";
          documentation = [ "https://netbird.io/docs/" ];
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          restartTriggers = [ configFile ];

          preStart = ''
            umask 077
            export AUTH_SECRET=$(cat "$CREDENTIALS_DIRECTORY/auth-secret")
            export ENCRYPTION_KEY=$(cat "$CREDENTIALS_DIRECTORY/encryption-key")
            export OWNER_HASH=$(cat "$CREDENTIALS_DIRECTORY/owner-password-hash")
            ${lib.getExe pkgs.envsubst} < ${configFile} > "${stateDir}/config.yaml"
          '';

          serviceConfig = {
            ExecStart = "${lib.getExe cfg.package} --config ${stateDir}/config.yaml";
            Restart = "always";

            LoadCredential = [
              "auth-secret:${cfg.authSecretFile}"
              "encryption-key:${cfg.encryptionKeyFile}"
              "owner-password-hash:${cfg.ownerPasswordHashFile}"
            ];

            StateDirectory = "netbird-server";
            StateDirectoryMode = "0750";
            UMask = "0077";
            WorkingDirectory = stateDir;

            # hardening
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            NoNewPrivileges = true;
            PrivateMounts = true;
            PrivateTmp = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectSystem = "strict";
            RemoveIPC = true;
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            User = "netbird";
            Group = "netbird";
          };

          stopIfChanged = false;
        };
      };
    };
}
