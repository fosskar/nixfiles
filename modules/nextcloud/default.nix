{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.nextcloud;
  acmeDomain = config.nixfiles.caddy.domain;
  inherit (config.nixfiles.authelia) publicDomain;
  serviceDomain = "cloud.${acmeDomain}";
  canonicalDomain = if publicDomain != null then "cloud.${publicDomain}" else serviceDomain;
  port = 8009;
  internalUrl = "http://127.0.0.1:${toString port}";
  oidcDomain = if publicDomain != null then publicDomain else acmeDomain;
  oidcIssuerUrl = "https://auth.${oidcDomain}";
in
{
  # --- options ---

  options.nixfiles.nextcloud = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "nextcloud with authelia oidc";
    };

  };

  config = lib.mkIf cfg.enable {
    # --- secrets ---

    clan.core.vars.generators.nextcloud = {
      files = {
        "admin-password" = {
          secret = true;
          owner = "nextcloud";
          group = "nextcloud";
        };
        "oauth-client-secret" = {
          secret = true;
          owner = "nextcloud";
          group = "nextcloud";
        };
        "oauth-client-secret-hash" = {
          secret = true;
          owner = "authelia-main";
          group = "authelia-main";
        };
      };

      runtimeInputs = with pkgs; [
        pwgen
        authelia
      ];
      script = ''
        pwgen -s 32 1 | tr -d '\n' > "$out/admin-password"

        secret=$(pwgen -s 64 1 | tr -d '\n')
        printf "%s" "$secret" > "$out/oauth-client-secret"
        authelia crypto hash generate pbkdf2 --password "$secret" \
          | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
      '';
    };

    # --- oidc ---

    services.authelia.instances.main.settings.identity_providers.oidc.clients = [
      {
        client_id = "nextcloud";
        client_name = "Nextcloud";
        client_secret = "{{ secret \"${
          config.clan.core.vars.generators.nextcloud.files."oauth-client-secret-hash".path
        }\" }}";
        public = false;
        consent_mode = "implicit";
        redirect_uris = [
          "https://${canonicalDomain}/apps/user_oidc/code"
          "https://${serviceDomain}/apps/user_oidc/code"
        ];
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
        response_types = [ "code" ];
        grant_types = [ "authorization_code" ];
        token_endpoint_auth_method = "client_secret_post";
      }
    ];

    # --- service ---

    # nextcloud creates its own nginx vhost; override default port to avoid
    # conflicting with caddy on :80, bind 0.0.0.0 so it's reachable via netbird
    services.nginx.defaultHTTPListenPort = port;
    services.nginx.virtualHosts.${canonicalDomain} = {
      serverAliases = [ serviceDomain ];
      listen = lib.mkForce [
        {
          addr = "0.0.0.0";
          inherit port;
        }
      ];
      extraConfig = ''
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
      '';
    };

    users.users.nextcloud.extraGroups = lib.mkAfter [ "shared" ];

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud33;
      datadir = "/tank/apps/nextcloud";
      hostName = canonicalDomain;
      https = false;
      autoUpdateApps.enable = false;
      appstoreEnable = false;

      caching = {
        apcu = true;
        redis = true;
      };
      configureRedis = true;

      notify_push = {
        enable = true;
        bendDomainToLocalhost = false;
        # keep notify_push traffic on internal nginx backend
        nextcloudUrl = "http://${serviceDomain}:${toString port}";
      };

      # socket auth — no dbpassFile
      database.createLocally = true;
      config = {
        adminuser = "admin";
        adminpassFile = config.clan.core.vars.generators.nextcloud.files."admin-password".path;
        dbtype = "pgsql";
      };

      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps)
          user_oidc
          calendar
          contacts
          groupfolders
          ;
        news = pkgs.fetchNextcloudApp {
          appName = "news";
          appVersion = "28.0.0-rc.2";
          license = "agpl3Plus";
          sha512 = "3l23683j88sa7k4kmyk3bx55nx737m9l93hlbf4m882jlydhaxv0p0n5aj107089hf4y5fsjc04apzwl7d4qclcbvpasmcppil4j2rc";
          url = "https://github.com/nextcloud/news/releases/download/28.0.0-rc.2/news.tar.gz";
        };
      };
      extraAppsEnable = true;

      phpExtraExtensions = all: [ all.smbclient ];
      phpOptions = {
        "opcache.interned_strings_buffer" = "16";
        "opcache.jit" = "1255";
        "opcache.jit_buffer_size" = "8M";
        "opcache.revalidate_freq" = "60";
      };

      # limit php-fpm for 2-user home setup (default max_children=120 is way too high)
      poolSettings = {
        pm = "dynamic";
        "pm.max_children" = "8";
        "pm.start_servers" = "2";
        "pm.min_spare_servers" = "1";
        "pm.max_spare_servers" = "4";
        "pm.max_requests" = "500";
      };

      settings = {
        overwriteprotocol = "https";
        "overwrite.cli.url" = "https://${canonicalDomain}";
        trusted_proxies = [
          "127.0.0.1"
          "192.168.10.200" # nixbox own IP — needed because external nginx proxies to nextcloud's localhost:8009
          "100.64.0.0/10" # NetBird CGNAT range (proxy source seen by notify_push setup checks)
        ];
        trusted_domains = [
          canonicalDomain
          serviceDomain
        ];

        default_phone_region = "DE";
        maintenance_window_start = 3;

        enabledPreviewProviders = [
          "OC\\Preview\\BMP"
          "OC\\Preview\\GIF"
          "OC\\Preview\\JPEG"
          "OC\\Preview\\Krita"
          "OC\\Preview\\MarkDown"
          "OC\\Preview\\MP3"
          "OC\\Preview\\OpenDocument"
          "OC\\Preview\\PNG"
          "OC\\Preview\\TXT"
          "OC\\Preview\\XBitmap"
          "OC\\Preview\\HEIC"
        ];

        # user_oidc app config (config.php level)
        user_oidc = {
          auto_provision = true;
          soft_auto_provision = true;
          "default_token_endpoint_auth_method" = "client_secret_post";
          login_label = "login with authelia";
        };
      };
    };

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Nextcloud";
        category = "Files";
        icon = "nextcloud.svg";
        href = "https://${canonicalDomain}";
        siteMonitor = "${internalUrl}/status.php";
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "Nextcloud";
        url = "https://${canonicalDomain}";
        group = "Files";
      }
    ];

    # --- caddy ---

    nixfiles.caddy.vhosts.cloud.port = port;

    # --- backup ---

    clan.core.postgresql.enable = true;
    clan.core.postgresql.databases.nextcloud = {
      create.enable = false;
      restore.stopOnRestore = [
        "nextcloud-cron.service"
        "nextcloud-oidc-bootstrap.service"
        "phpfpm-nextcloud.service"
      ];
    };

    # --- systemd ---

    # bootstrap oidc provider in nextcloud DB via occ
    # user_oidc:provider is idempotent (creates or updates)
    systemd.services.nextcloud-oidc-bootstrap = {
      description = "bootstrap nextcloud user_oidc provider";
      after = [ "nextcloud-setup.service" ];
      requires = [ "nextcloud-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        inherit (config.systemd.services.nextcloud-cron.serviceConfig)
          User
          LoadCredential
          ;
      };
      script = ''
        set -euo pipefail

        occ=${lib.getExe config.services.nextcloud.occ}
        secret=$(cat ${config.clan.core.vars.generators.nextcloud.files."oauth-client-secret".path})

        "$occ" user_oidc:provider authelia \
          --clientid="nextcloud" \
          --clientsecret="$secret" \
          --discoveryuri="${oidcIssuerUrl}/.well-known/openid-configuration" \
          --scope="openid email profile groups" \
          --mapping-groups="groups" \
          --mapping-display-name="name" \
          --mapping-email="email" \
          --group-provisioning=1

        # app policy
        "$occ" app:enable activity || true

        # disable apps we don't use
        for app in \
          photos \
          weather_status \
          recommendations \
          support \
          nextcloud_announcements \
          related_resources \
          federation \
          cloud_federation_api \
          federatedfilesharing \
          lookup_server_connector \
          circles \
          dashboard \
          firstrunwizard \
          user_status \
          logreader \
          webhook_listeners \
          app_api \
          systemtags \
          password_policy \
          sharebymail \
          files_downloadlimit \
          survey_client
        do
          "$occ" app:disable "$app" || true
        done

        # allow users to mount their own SMB external storage
        "$occ" app:enable files_external
        "$occ" config:app:set files_external allow_user_mounting --value=yes
        "$occ" config:app:set files_external user_mounting_backends --value=smb

        # declarative admin external mount: /shared -> /tank/shares/shared
        mounts="$($occ files_external:list --output=json_pretty 2>/dev/null || echo '[]')"

        # cleanup legacy root mount if present
        for mid in $(${pkgs.jq}/bin/jq -r '.[] | select(.mount_point == "/" and .storage == "\\OC\\Files\\Storage\\Local") | .mount_id' <<< "$mounts"); do
          printf 'y\n' | "$occ" files_external:delete "$mid" >/dev/null || true
        done

        shared_mid=$(${pkgs.jq}/bin/jq -r '.[] | select(.mount_point == "/shared" and .storage == "\\OC\\Files\\Storage\\Local") | .mount_id' <<< "$mounts" | head -n1)
        if [ -n "$shared_mid" ] && [ "$shared_mid" != "null" ]; then
          "$occ" files_external:config "$shared_mid" datadir /tank/shares/shared >/dev/null || true
        else
          "$occ" files_external:create /shared local null::null -c datadir=/tank/shares/shared >/dev/null || true
        fi

        # notify_push endpoint clients use (public URL)
        "$occ" config:app:set notify_push base_endpoint --value="https://${canonicalDomain}/push"
      '';
    };
  };
}
