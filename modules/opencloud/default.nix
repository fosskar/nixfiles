{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.opencloud;
  acmeDomain = config.nixfiles.acme.domain;
  inherit (config.nixfiles.authelia) publicDomain;
  serviceDomain = "cloud.${acmeDomain}";
  oidcDomain = if publicDomain != null then publicDomain else acmeDomain;
  oidcIssuerUrl = "https://auth.${oidcDomain}";
  port = 9200;

  # all opencloud clients need to be registered in the IDP
  # client IDs are hardcoded in the apps — see docs
  publicDomainUris = lib.optionals (publicDomain != null) [
    "https://cloud.${publicDomain}/"
    "https://cloud.${publicDomain}/oidc-callback.html"
    "https://cloud.${publicDomain}/oidc-silent-redirect.html"
    "https://cloud.${publicDomain}/web-oidc-callback"
  ];

  # OIDC origins that need to be in CSP connect-src
  oidcOrigins = [
    "https://auth.${acmeDomain}"
  ]
  ++ lib.optionals (publicDomain != null) [ "https://auth.${publicDomain}" ];

  settingsFormat = pkgs.formats.yaml { };

  cspConfig = {
    directives = {
      child-src = [ "'self'" ];
      connect-src = [
        "'self'"
        "blob:"
        "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"
        "https://update.opencloud.eu/"
      ]
      ++ oidcOrigins;
      default-src = [ "'none'" ];
      font-src = [ "'self'" ];
      frame-ancestors = [ "'self'" ];
      frame-src = [
        "'self'"
        "blob:"
        "https://embed.diagrams.net/"
      ];
      img-src = [
        "'self'"
        "data:"
        "blob:"
        "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"
      ];
      manifest-src = [ "'self'" ];
      media-src = [ "'self'" ];
      object-src = [
        "'self'"
        "blob:"
      ];
      script-src = [
        "'self'"
        "'unsafe-inline'"
      ];
      style-src = [
        "'self'"
        "'unsafe-inline'"
      ];
    };
  };
in
{
  options.nixfiles.opencloud = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "opencloud file sharing with authelia oidc";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/tank/apps/opencloud/data";
      description = "directory for user file storage (posix driver root)";
    };
  };

  config = lib.mkIf cfg.enable {
    # admin password for initial setup
    clan.core.vars.generators.opencloud = {
      files."admin-password" = { };
      runtimeInputs = [ pkgs.pwgen ];
      script = ''
        pwgen -s 32 1 | tr -d '\n' > "$out/admin-password"
      '';
    };

    # authelia oidc cors — opencloud web does cross-origin calls to auth.<domain>
    services.authelia.instances.main.settings.identity_providers.oidc.cors = {
      allowed_origins_from_client_redirect_uris = true;
      endpoints = [
        "authorization"
        "token"
        "userinfo"
        "revocation"
      ];
    };

    # authelia oidc clients — all public (PKCE), no secrets needed
    # web client_id = "web" (hardcoded in opencloud web app)
    # desktop/mobile client_ids are hardcoded in their respective apps
    services.authelia.instances.main.settings.identity_providers.oidc.clients = [
      {
        client_id = "web";
        client_name = "OpenCloud Web";
        public = true;
        consent_mode = "implicit";
        redirect_uris = [
          "https://${serviceDomain}/"
          "https://${serviceDomain}/oidc-callback.html"
          "https://${serviceDomain}/oidc-silent-redirect.html"
          "https://${serviceDomain}/web-oidc-callback"
        ]
        ++ publicDomainUris;
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
        response_types = [ "code" ];
        grant_types = [ "authorization_code" ];
        token_endpoint_auth_method = "none";
      }
      {
        client_id = "OpenCloudDesktop";
        client_name = "OpenCloud Desktop";
        public = true;
        consent_mode = "implicit";
        redirect_uris = [
          "http://127.0.0.1"
          "http://localhost"
        ];
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
          "offline_access"
        ];
        response_types = [ "code" ];
        grant_types = [ "authorization_code" ];
        token_endpoint_auth_method = "none";
      }
      {
        client_id = "OpenCloudAndroid";
        client_name = "OpenCloud Android";
        public = true;
        consent_mode = "implicit";
        redirect_uris = [ "oc://android.opencloud.eu" ];
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
          "offline_access"
        ];
        response_types = [ "code" ];
        grant_types = [ "authorization_code" ];
        token_endpoint_auth_method = "none";
      }
      {
        client_id = "OpenCloudIOS";
        client_name = "OpenCloud iOS";
        public = true;
        consent_mode = "implicit";
        redirect_uris = [ "oc://ios.opencloud.eu" ];
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
          "offline_access"
        ];
        response_types = [ "code" ];
        grant_types = [ "authorization_code" ];
        token_endpoint_auth_method = "none";
      }
    ];

    services.opencloud = {
      enable = true;
      url = "https://${serviceDomain}";
      address = "127.0.0.1";
      inherit port;

      environment = {
        PROXY_TLS = "false";
        OC_INSECURE = "true";
        OC_LOG_LEVEL = "warn";
        PROXY_CSP_CONFIG_FILE_LOCATION = "/etc/opencloud/csp.yaml";

        # external OIDC via authelia — disable built-in IDP
        OC_OIDC_ISSUER = oidcIssuerUrl;
        OC_EXCLUDE_RUN_SERVICES = "idp";
        PROXY_AUTOPROVISION_ACCOUNTS = "true";
        PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";
        PROXY_USER_OIDC_CLAIM = "preferred_username";
        PROXY_USER_CS3_CLAIM = "username";
        GRAPH_USERNAME_MATCH = "none";
        GRAPH_ASSIGN_DEFAULT_USER_ROLE = "false";

        # posix driver — inotify watches for external changes (samba/paperless)
        STORAGE_USERS_POSIX_ROOT = cfg.dataDir;
        STORAGE_USERS_POSIX_WATCH_FS = "true";
      };

      # role mapping + web OIDC config via yaml settings
      settings = {
        proxy = {
          oidc.rewrite_well_known = true;
          role_assignment = {
            driver = "oidc";
            oidc_role_mapper = {
              role_claim = "groups";
              role_mapping = [
                {
                  role_name = "admin";
                  claim_value = "admin";
                }
                {
                  role_name = "spaceadmin";
                  claim_value = "user";
                }
                {
                  role_name = "user";
                  claim_value = "user";
                }
              ];
            };
          };
        };
        web.web.config.oidc = {
          authority = oidcIssuerUrl;
          client_id = "web";
          scope = "openid profile email groups";
        };
      };
    };

    # CSP config — default opencloud CSP + external OIDC origins in connect-src
    environment.etc."opencloud/csp.yaml".source = settingsFormat.generate "csp.yaml" cspConfig;

    # allow opencloud to write to dataDir (ProtectSystem=strict blocks it otherwise)
    # add inotify-tools to PATH for posix driver filesystem watching
    systemd.services.opencloud.serviceConfig.ReadWritePaths = [ cfg.dataDir ];
    systemd.services.opencloud.path = [ pkgs.inotify-tools ];

    # persist service state on ephemeral root (metadata, IDM, nats, search index, config)
    # dataDir on /tank doesn't need persistence — ZFS pool survives reboots
    nixfiles.persistence.directories = [
      {
        directory = "/var/lib/opencloud";
        user = "opencloud";
        group = "opencloud";
      }
    ];

    # ensure data dir exists with correct ownership
    systemd.tmpfiles.settings."10-opencloud-data" = {
      ${cfg.dataDir}.d = {
        user = "opencloud";
        group = "opencloud";
        mode = "0750";
      };
    };

    # nginx reverse proxy — opencloud needs buffering off for SSE + long timeouts
    services.nginx.virtualHosts."${serviceDomain}" = {
      useACMEHost = acmeDomain;
      forceSSL = true;
      extraConfig = ''
        client_max_body_size 10G;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        recommendedProxySettings = true;
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
          proxy_request_buffering off;
          proxy_read_timeout 3600s;
          proxy_send_timeout 3600s;
          proxy_next_upstream off;
        '';
      };
    };

    # backup service state — dataDir on /tank is already covered by ZFS snapshots + borgbackup
    clan.core.state.opencloud.folders = [
      "/var/lib/opencloud"
    ];
  };
}
