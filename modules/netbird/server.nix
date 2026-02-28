# netbird server (management + signal + relay + stun + embedded IdP)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.netbird.server;
  stateDir = "/var/lib/netbird-server";
  settingsFormat = pkgs.formats.yaml { };
  # config without secrets — secrets injected at runtime
  configFile = settingsFormat.generate "netbird-server.yaml" cfg.settings;
in
{
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

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "open firewall for HTTPS, HTTP, and STUN";
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
    services.netbird.server.settings = {
      server = {
        listenAddress = lib.mkDefault ":8081";
        exposedAddress = lib.mkDefault "https://${cfg.domain}:443";
        metricsPort = lib.mkDefault 9090;
        healthcheckAddress = lib.mkDefault ":9000";
        logLevel = lib.mkDefault cfg.logLevel;
        logFile = lib.mkDefault "console";
        dataDir = lib.mkDefault stateDir;
        disableAnonymousMetrics = lib.mkDefault true;
        disableGeoliteUpdate = lib.mkDefault true;

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
          # owner placeholder — replaced in preStart
          owner = {
            email = cfg.ownerEmail;
            password = "__OWNER_HASH__";
          };
        };

        store.engine = lib.mkDefault "sqlite";

        # secrets are placeholders — replaced in preStart
        authSecret = "__AUTH_SECRET__";
        store.encryptionKey = "__ENCRYPTION_KEY__";
      };
    };

    systemd.services.netbird-server = {
      description = "netbird server (management + signal + relay)";
      documentation = [ "https://netbird.io/docs/" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ configFile ];

      preStart = ''
        umask 077
        AUTH_SECRET=$(cat "$CREDENTIALS_DIRECTORY/auth-secret")
        ENCRYPTION_KEY=$(cat "$CREDENTIALS_DIRECTORY/encryption-key")
        OWNER_HASH=$(cat "$CREDENTIALS_DIRECTORY/owner-password-hash")
        ${lib.getExe pkgs.gnused} \
          -e "s|__AUTH_SECRET__|$AUTH_SECRET|g" \
          -e "s|__ENCRYPTION_KEY__|$ENCRYPTION_KEY|g" \
          -e "s|__OWNER_HASH__|$OWNER_HASH|g" \
          ${configFile} > "${stateDir}/config.yaml"
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

      };

      stopIfChanged = false;
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [
        80
        443
      ];
      # STUN
      allowedUDPPorts = [ 3478 ];
    };
  };
}
