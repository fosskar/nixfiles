{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.nextcloud;
  acmeDomain = config.nixfiles.acme.domain;
  inherit (config.nixfiles.authelia) publicDomain;
  serviceDomain = "cloud.${acmeDomain}";
  port = 8009;
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
          "https://${serviceDomain}/apps/user_oidc/code"
          "https://cloud.${publicDomain}/apps/user_oidc/code"
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

    # nextcloud creates its own nginx vhost at hostName; pin it to 0.0.0.0:port
    # so it's reachable by traefik on hzc-pango via netbird
    services.nginx.virtualHosts."localhost".listen = [
      {
        addr = "0.0.0.0";
        inherit port;
      }
    ];

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud33;
      datadir = "/tank/apps/nextcloud";
      hostName = "localhost";
      https = false;
      autoUpdateApps.enable = false;

      notify_push = {
        enable = true;
        bendDomainToLocalhost = false;
        nextcloudUrl = "https://${serviceDomain}";
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
        "overwrite.cli.url" = "https://${serviceDomain}";
        trusted_proxies = [
          "127.0.0.1"
          "192.168.10.80" # hm-nixbox own IP — needed because external nginx proxies to nextcloud's localhost:8009
        ];
        trusted_domains = [
          "127.0.0.1"
          serviceDomain
          "cloud.${publicDomain}"
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

    # --- nginx ---

    nixfiles.nginx.vhosts.cloud = {
      inherit port;
      extraConfig = "client_max_body_size 512M;";
    };

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

    clan.core.state.nextcloud.folders = [ "/tank/apps/nextcloud" ];

    # --- systemd ---

    # notify_push daemon talks directly to nextcloud, bypassing external nginx
    systemd.services.nextcloud-notify_push.environment.NEXTCLOUD_URL =
      lib.mkForce "http://localhost:${toString port}";

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

        # disable bundled apps we don't use
        "$occ" app:disable photos

        # allow users to mount their own SMB external storage
        "$occ" config:app:set files_external allow_user_mounting --value=yes
        "$occ" config:app:set files_external user_mounting_backends --value=smb
      '';
    };
  };
}
