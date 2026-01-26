{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.filebrowser-quantum;
  acmeDomain = config.nixfiles.acme.domain;
  inherit (config.nixfiles.authelia) publicDomain;
  serviceDomain = "files.${acmeDomain}";

  format = pkgs.formats.yaml { };

  # merge user settings with defaults
  configFile = format.generate "config.yaml" (
    lib.recursiveUpdate {
      server = {
        inherit (cfg) port;
        inherit (cfg) baseURL;
        database = "/var/lib/filebrowser-quantum/database.db";
      };
    } cfg.settings
  );
in
{
  options.nixfiles.filebrowser-quantum = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "filebrowser-quantum web file manager with authelia SSO";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "port to listen on";
    };

    baseURL = lib.mkOption {
      type = lib.types.str;
      default = "/";
      description = "base URL path";
    };

    sources = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [
        {
          name = "shared";
          path = "/tank/shares/shared";
        }
        {
          name = "media";
          path = "/tank/media";
        }
      ];
      description = "file sources to expose";
    };

    settings = lib.mkOption {
      inherit (format) type;
      default = { };
      description = "additional settings for filebrowser-quantum";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "shared"
        "media"
      ];
      description = "extra groups for filebrowser-quantum user (for filesystem access)";
    };
  };

  config = lib.mkIf cfg.enable {
    # boltdb backup for borgbackup (filebrowser-quantum uses storm/boltdb, not sqlite)
    clan.core.state.filebrowser-quantum = {
      folders = [ "/var/backup/filebrowser-quantum" ];
      preBackupScript = ''
        export PATH=${lib.makeBinPath [ pkgs.coreutils ]}
        mkdir -p /var/backup/filebrowser-quantum
        cp /var/lib/filebrowser-quantum/database.db /var/backup/filebrowser-quantum/database.db
      '';
    };

    # generate filebrowser-quantum secrets
    clan.core.vars.generators.filebrowser-quantum = {
      files = {
        "oauth-client-secret-hash" = { };
        "oauth-client-secret" = { };
        "admin-password" = { };
        "secrets.env" = { };
      };

      runtimeInputs = with pkgs; [
        pwgen
        authelia
      ];
      script = ''
        # oidc client secret
        SECRET=$(pwgen -s 64 1)
        authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 > "$out/oauth-client-secret-hash"
        echo -n "$SECRET" > "$out/oauth-client-secret"

        # admin password
        ADMIN=$(pwgen -s 32 1)
        echo -n "$ADMIN" > "$out/admin-password"

        # env file with both secrets
        {
          echo "FILEBROWSER_OIDC_CLIENT_SECRET=$SECRET"
          echo "FILEBROWSER_ADMIN_PASSWORD=$ADMIN"
        } > "$out/secrets.env"
      '';
    };

    # register oidc client with authelia
    # clan vars get hm-nixbox filebrowser-quantum/oauth-client-secret-hash
    services.authelia.instances.main.settings.identity_providers.oidc.clients = [
      {
        client_id = "filebrowser-quantum";
        client_name = "Filebrowser Quantum";
        client_secret = "$pbkdf2-sha512$310000$ZYhpHYGG/1Kec9Lv5Q1JHQ$y2ghAiROnsN6kTRh2AXV6.5eZJVRNHXxnZ1m22rBZw1wyPTQkNtJMP977Jt8nYPJo8JNDDR./uuoseRfpgk1.w";
        public = false;
        consent_mode = "implicit";
        require_pkce = false;
        redirect_uris = [
          "https://${serviceDomain}/api/auth/oidc/callback"
        ];
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

    # nginx reverse proxy
    nixfiles.nginx.vhosts.files.port = cfg.port;

    # systemd service
    systemd.services.filebrowser-quantum = {
      description = "filebrowser-quantum web file manager";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.custom.filebrowser-quantum}";
        WorkingDirectory = "/var/lib/filebrowser-quantum";
        EnvironmentFile = config.clan.core.vars.generators.filebrowser-quantum.files."secrets.env".path;

        User = "filebrowser-quantum";
        Group = "filebrowser-quantum";

        StateDirectory = "filebrowser-quantum";
        StateDirectoryMode = "0750";

        # hardening
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        MemoryDenyWriteExecute = true;
        LockPersonality = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        DevicePolicy = "closed";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        SystemCallArchitectures = "native";
        CapabilityBoundingSet = "";
        UMask = "0077";
      };

      preStart = ''
        ln -sf ${configFile} /var/lib/filebrowser-quantum/config.yaml
      '';
    };

    users.users.filebrowser-quantum = {
      group = "filebrowser-quantum";
      isSystemUser = true;
      inherit (cfg) extraGroups;
    };

    users.groups.filebrowser-quantum = { };

    # default settings with OIDC
    nixfiles.filebrowser-quantum.settings = {
      auth.methods.oidc = {
        enabled = true;
        clientId = "filebrowser-quantum";
        issuerUrl = "https://auth.${publicDomain}";
        scopes = "openid profile email groups";
        userIdentifier = "preferred_username";
        createUser = true;
        logoutRedirectUrl = "https://auth.${publicDomain}/logout";
      };
      server.sources = cfg.sources;
      userDefaults.darkMode = true;
    };
  };
}
