{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.opencloud;
  acmeDomain = config.nixfiles.caddy.domain;
  inherit (config.nixfiles.authelia) publicDomain;
  serviceDomain = "opencloud.${acmeDomain}";
  bindAddress = "0.0.0.0";
  port = 9200;
  internalUrl = "http://127.0.0.1:${toString port}";
  oidcDomain = if publicDomain != null then publicDomain else acmeDomain;
  oidcIssuerUrl = "https://auth.${oidcDomain}";

  # all opencloud clients need to be registered in the IDP
  # client IDs are hardcoded in the apps — see docs
  publicDomainUris = lib.optionals (publicDomain != null) [
    "https://opencloud.${publicDomain}/"
    "https://opencloud.${publicDomain}/oidc-callback.html"
    "https://opencloud.${publicDomain}/oidc-silent-redirect.html"
    "https://opencloud.${publicDomain}/web-oidc-callback"
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
    consent_mode = "pre-configured";
    pre_configured_consent_duration = "1y";
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
  # --- options ---

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
    # --- secrets ---

    clan.core.vars.generators.opencloud = {
      files."admin-password" = { };
      runtimeInputs = [ pkgs.pwgen ];
      script = ''
        pwgen -s 32 1 | tr -d '\n' > "$out/admin-password"
      '';
    };

    # --- oidc ---

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

    # --- service ---

    services.opencloud = {
      enable = true;
      url = "https://${serviceDomain}";
      address = bindAddress;
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
        STORAGE_USERS_POSIX_USE_SPACE_GROUPS = "true";
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

    # radicale — caldav/carddav server, auth via X-Remote-User from opencloud proxy
    services.radicale = {
      enable = true;
      settings = {
        server.hosts = [ "127.0.0.1:5232" ];
        auth.type = "http_x_remote_user";
        storage.filesystem_folder = "/var/lib/radicale/collections";
      };
    };

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "OpenCloud";
        category = "Documents";
        icon = "https://opencloud.${acmeDomain}/themes/opencloud/assets/favicon.svg";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "OpenCloud";
        url = "https://${serviceDomain}";
        group = "Documents";
      }
    ];

    # --- caddy ---

    services.caddy.virtualHosts."${serviceDomain}".extraConfig = ''
      reverse_proxy ${internalUrl} {
        flush_interval -1
        transport http {
          read_timeout 3600s
          write_timeout 3600s
        }
      }
      request_body {
        max_size 10GB
      }
    '';

    # --- backup ---

    clan.core.state.radicale.folders = [
      "/var/lib/radicale"
      "/var/lib/opencloud"
    ];

    # --- persistence ---

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

    # --- systemd ---

    # allow opencloud to write to dataDir (ProtectSystem=strict blocks it otherwise)
    # add inotify-tools to PATH for posix driver filesystem watching
    systemd.services.opencloud.serviceConfig.ReadWritePaths = [ cfg.dataDir ];
    systemd.services.opencloud.path = [ pkgs.inotify-tools ];

    # ensure data dir exists with correct ownership
    systemd.tmpfiles.settings."10-opencloud-data" = {
      ${cfg.dataDir}.d = {
        user = "opencloud";
        group = "opencloud";
        mode = "0750";
      };
    };

    # opencloud hardcodes 0600 on uploaded files — fix group permissions so other
    # services (paperless, samba) in the opencloud group can read/write them
    systemd.services.opencloud-permission-fixer = {
      description = "fix opencloud file permissions for group access";
      after = [ "opencloud.service" ];
      requires = [ "opencloud.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.inotify-tools
        pkgs.coreutils
        pkgs.findutils
      ];
      serviceConfig = {
        Type = "simple";
        User = "opencloud";
        Group = "opencloud";
        Restart = "always";
        RestartSec = 5;
        ExecStart = pkgs.writeShellScript "opencloud-permission-fixer" ''
          ${pkgs.inotify-tools}/bin/inotifywait -m -r -e create,moved_to --format '%w%f' "${cfg.dataDir}" | while read -r path; do
            if [ -f "$path" ]; then
              chmod g+rw "$path"
            elif [ -d "$path" ]; then
              chmod g+rwx "$path"
            fi
          done
        '';
      };
    };
  };
}
