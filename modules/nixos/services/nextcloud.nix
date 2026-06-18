{
  flake.modules.nixos.nextcloud =
    {
      flake-self,
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "cloud";
      localHost = "${serviceName}.${flake-self.domains.local}";
      publicHost = "${serviceName}.${flake-self.domains.public}";
      listenPort = 8009;
      listenUrl = "http://127.0.0.1:${toString listenPort}";
      oidcIssuerUrl = "https://auth.${flake-self.domains.public}";
      nixfilesPackages = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
      tankDisks = [
        "/dev/sda"
        "/dev/sdc"
        "/dev/sdd"
        "/dev/sdg"
      ];
      nextcloudCronCommand = "${lib.getExe config.services.phpfpm.pools.nextcloud.phpPackage} -f ${config.services.nextcloud.finalPackage}/cron.php";
      nextcloudCronIfTankAwake = pkgs.writeShellScript "nextcloud-cron-if-tank-awake" ''
        set -eu

        for disk in ${lib.escapeShellArgs tankDisks}; do
          if ! ${lib.getExe pkgs.smartmontools} --info --nocheck=standby "$disk" 2>&1 | ${lib.getExe pkgs.gnugrep} -qi "standby"; then
            exec ${nextcloudCronCommand}
          fi
        done

        echo "tank disks standby; skipping nextcloud cron"
      '';
    in
    {
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

        runtimeInputs = [
          pkgs.pwgen
          pkgs.authelia
        ];
        script = ''
          pwgen -s 32 1 | tr -d '\n' > "$out/admin-password"

          secret=$(pwgen -s 64 1 | tr -d '\n')
          printf "%s" "$secret" > "$out/oauth-client-secret"
          authelia crypto hash generate pbkdf2 --password "$secret" \
            | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
        '';
      };

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = "nextcloud";
          client_name = "Nextcloud";
          client_secret = "{{ secret \"${
            config.clan.core.vars.generators.nextcloud.files."oauth-client-secret-hash".path
          }\" }}";
          public = false;
          consent_mode = "implicit";
          authorization_policy = "users";
          redirect_uris = [
            "https://${publicHost}/apps/user_oidc/code"
            "https://${localHost}/apps/user_oidc/code"
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

      services.nginx.defaultHTTPListenPort = listenPort;
      services.nginx.virtualHosts.${publicHost} = {
        serverAliases = [ localHost ];
        listen = lib.mkForce [
          {
            addr = "0.0.0.0";
            port = listenPort;
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
        hostName = publicHost;
        https = false;
        autoUpdateApps.enable = false;
        appstoreEnable = false;
        maxUploadSize = "4G";

        caching = {
          apcu = true;
          redis = true;
        };
        configureRedis = true;

        notify_push = {
          enable = true;
          bendDomainToLocalhost = false;
          nextcloudUrl = "http://${localHost}:${toString listenPort}";
        };

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
            tasks
            ;
          news = nixfilesPackages.nextcloud-news;
        };
        extraAppsEnable = true;

        phpExtraExtensions = all: [ all.smbclient ];
        phpOptions = {
          "opcache.interned_strings_buffer" = "16";
          "opcache.jit" = "1255";
          "opcache.jit_buffer_size" = "8M";
          "opcache.revalidate_freq" = "60";
          "redis.session.locking_enabled" = "1";
          "redis.session.lock_retries" = "-1";
          "redis.session.lock_wait_time" = "10000";
        };

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
          "overwrite.cli.url" = "https://${publicHost}";
          trusted_proxies = [
            "127.0.0.1"
            "192.168.20.200"
            "100.64.0.0/10"
          ];
          trusted_domains = [
            publicHost
            localHost
          ];

          default_phone_region = "DE";
          maintenance_window_start = 3;
          chunkSize = "5120MB";

          mail_smtpmode = "sendmail";
          mail_sendmailmode = "pipe";
          mail_from_address = "noreply";
          mail_domain = "nx3.eu";

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

          user_oidc = {
            auto_provision = true;
            soft_auto_provision = true;
            "default_token_endpoint_auth_method" = "client_secret_post";
            login_label = "login with authelia";
          };
        };
      };

      services.homepage-dashboard.services = [
        {
          "files" = [
            {
              "Nextcloud" = {
                href = "https://${publicHost}";
                icon = "nextcloud.svg";
                siteMonitor = "${listenUrl}/status.php";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Nextcloud";
          url = "https://${publicHost}";
          group = "Files";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl} {
          flush_interval -1
        }
      '';

      clan.core.postgresql.enable = true;
      clan.core.postgresql.databases.nextcloud = {
        create.enable = false;
        restore.stopOnRestore = [
          "nextcloud-cron.service"
          "nextcloud-oidc-bootstrap.service"
          "phpfpm-nextcloud.service"
        ];
      };

      systemd.services.nextcloud-setup = {
        after = [ "redis-nextcloud.service" ];
        requires = [ "redis-nextcloud.service" ];
      };

      systemd.services.nextcloud-cron.serviceConfig.ExecStart = lib.mkForce nextcloudCronIfTankAwake;

      systemd.services.nextcloud-cron-force = {
        description = "forced nextcloud cron run";
        after = config.systemd.services.nextcloud-cron.after;
        requires = config.systemd.services.nextcloud-cron.requires;
        environment = config.systemd.services.nextcloud-cron.environment;
        serviceConfig = {
          inherit (config.systemd.services.nextcloud-cron.serviceConfig)
            ExecCondition
            KillMode
            LoadCredential
            Type
            User
            ;
          ExecStart = nextcloudCronCommand;
        };
      };

      systemd.timers.nextcloud-cron-force = {
        description = "daily forced nextcloud cron run";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 03:05:00";
          Persistent = true;
        };
      };

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
            --unique-uid=1 \
            --mapping-uid="sub" \
            --mapping-groups="groups" \
            --mapping-display-name="name" \
            --mapping-email="email" \
            --group-provisioning=1

          "$occ" app:enable activity || true

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

          "$occ" app:enable files_external
          "$occ" config:app:set files_external allow_user_mounting --value=yes
          "$occ" config:app:set files_external user_mounting_backends --value=smb

          mounts="$($occ files_external:list --output=json_pretty 2>/dev/null || echo '[]')"

          for mid in $(${pkgs.jq}/bin/jq -r '.[] | select(.mount_point == "/" and .storage == "\\OC\\Files\\Storage\\Local") | .mount_id' <<< "$mounts"); do
            printf 'y\n' | "$occ" files_external:delete "$mid" >/dev/null || true
          done

          shared_mid=$(${pkgs.jq}/bin/jq -r '.[] | select(.mount_point == "/shared" and .storage == "\\OC\\Files\\Storage\\Local") | .mount_id' <<< "$mounts" | head -n1)
          if [ -n "$shared_mid" ] && [ "$shared_mid" != "null" ]; then
            "$occ" files_external:config "$shared_mid" datadir /tank/shares/shared >/dev/null || true
          else
            "$occ" files_external:create /shared local null::null -c datadir=/tank/shares/shared >/dev/null || true
          fi

          "$occ" config:app:set notify_push base_endpoint --value="https://${publicHost}/push"
        '';
      };
    };
}
