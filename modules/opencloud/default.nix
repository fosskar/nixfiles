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

  # OIDC origins that need to be in CSP connect-src + frame-src
  oidcOrigins = [
    "https://auth.${acmeDomain}"
  ]
  ++ lib.optionals (publicDomain != null) [ "https://auth.${publicDomain}" ];

  settingsFormat = pkgs.formats.yaml { };

  # shared OIDC client config — all opencloud clients are public PKCE
  commonClientConfig = {
    public = true;
    consent_mode = "implicit";
    scopes = [
      "openid"
      "profile"
      "email"
      "groups"
      "offline_access"
    ];
    response_types = [ "code" ];
    grant_types = [
      "authorization_code"
      "refresh_token"
    ];
    token_endpoint_auth_method = "none";
  };

  # helper for radicale proxy routes
  radicaleRoute = endpoint: scriptName: {
    inherit endpoint;
    backend = "http://127.0.0.1:5232";
    remote_user_header = "X-Remote-User";
    skip_x_access_token = true;
    additional_headers = [ { "X-Script-Name" = scriptName; } ];
  };

  # only additions to opencloud's default CSP — deep-merged at runtime
  cspConfig = {
    directives = {
      # external OIDC provider needs to be in connect-src for API calls
      connect-src = oidcOrigins;
      # needed for silent OIDC token renewal via iframe (oidc-silent-redirect.html)
      frame-src = oidcOrigins;
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
      (
        commonClientConfig
        // {
          client_id = "web";
          client_name = "OpenCloud Web";
          redirect_uris = [
            "https://${serviceDomain}/"
            "https://${serviceDomain}/oidc-callback.html"
            "https://${serviceDomain}/oidc-silent-redirect.html"
            "https://${serviceDomain}/web-oidc-callback"
          ]
          ++ publicDomainUris;
        }
      )
      (
        commonClientConfig
        // {
          client_id = "OpenCloudDesktop";
          client_name = "OpenCloud Desktop";
          redirect_uris = [
            "http://127.0.0.1"
            "http://localhost"
          ];
        }
      )
      (
        commonClientConfig
        // {
          client_id = "OpenCloudAndroid";
          client_name = "OpenCloud Android";
          redirect_uris = [ "oc://android.opencloud.eu" ];
        }
      )
      (
        commonClientConfig
        // {
          client_id = "OpenCloudIOS";
          client_name = "OpenCloud iOS";
          redirect_uris = [ "oc://ios.opencloud.eu" ];
        }
      )
    ];

    services.opencloud = {
      enable = true;
      url = "https://${serviceDomain}";
      address = "0.0.0.0";
      inherit port;

      environment = {
        PROXY_TLS = "false";
        OC_INSECURE = "true";
        OC_LOG_LEVEL = "warn";
        PROXY_CSP_CONFIG_FILE_LOCATION = "${settingsFormat.generate "csp.yaml" cspConfig}";

        # external OIDC via authelia — disable built-in IDP
        OC_OIDC_ISSUER = oidcIssuerUrl;
        OC_EXCLUDE_RUN_SERVICES = "idp";
        PROXY_AUTOPROVISION_ACCOUNTS = "true";

        PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";
        PROXY_OIDC_USERINFO_CACHE_TTL = "10m";
        GRAPH_ASSIGN_DEFAULT_USER_ROLE = "true";
        GRAPH_SPACES_DEFAULT_QUOTA = "107374182400"; # 100GB
        PROXY_USER_OIDC_CLAIM = "sub";
        PROXY_USER_CS3_CLAIM = "username";
        GRAPH_USERNAME_MATCH = "none";
        WEB_OPTION_ACCOUNT_EDIT_LINK = "https://auth.${oidcDomain}/settings";

        # posix driver — inotify watches for external changes (samba/paperless)
        STORAGE_USERS_POSIX_ROOT = cfg.dataDir;
        STORAGE_USERS_POSIX_WATCH_FS = "true";
      };

      # role mapping, radicale proxy routes, web OIDC config via yaml settings
      settings = {
        proxy = {
          oidc.rewrite_well_known = true;
          # default driver assigns 'user' role to all new users
          # oidc driver can't work because mobile/desktop apps don't request 'groups' scope
          # see: https://github.com/opencloud-eu/opencloud/issues/1592
          role_assignment.driver = "default";
          # proxy caldav/carddav to radicale for calendar+contacts
          additional_policies = [
            {
              name = "default";
              routes = [
                (radicaleRoute "/caldav/" "/caldav")
                (radicaleRoute "/.well-known/caldav" "/caldav")
                (radicaleRoute "/carddav/" "/carddav")
                (radicaleRoute "/.well-known/carddav" "/carddav")
              ];
            }
          ];
        };
        web.web.config.oidc = {
          authority = oidcIssuerUrl;
          client_id = "web";
          scope = "openid profile email groups offline_access";
        };
      };
    };

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
      {
        directory = "/var/lib/radicale";
        user = "radicale";
        group = "radicale";
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

    # radicale — caldav/carddav server, auth via X-Remote-User from opencloud proxy
    services.radicale = {
      enable = true;
      settings = {
        server = {
          hosts = [ "127.0.0.1:5232" ];
        };
        auth = {
          type = "http_x_remote_user";
        };
        storage = {
          filesystem_folder = "/var/lib/radicale/collections";
        };
      };
    };

    # backup service state — dataDir on /tank is already covered by ZFS snapshots + borgbackup
    clan.core.state.radicale.folders = [
      "/var/lib/radicale"
      "/var/lib/opencloud"
    ];
  };
}
