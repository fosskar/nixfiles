{
  # self-hosted TRMNL server; trmnl.com refuses ICS urls that resolve to
  # private addresses, so calendars on nx3.eu need a server inside the lan
  flake.modules.nixos.larapaper =
    {
      flake-self,
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      serviceName = "trmnl";
      localHost = "${serviceName}.${flake-self.domains.local}";
      user = "larapaper";
      dataDir = "/var/lib/larapaper";
      package = pkgs.local.larapaper;
      php = package.phpPackage;
      artisan = "${php}/bin/php ${package}/artisan";
      secretEnv = config.clan.core.vars.generators.larapaper.files."secret.env".path;
      socket = config.services.phpfpm.pools.larapaper.socket;

      environment = {
        APP_ENV = "production";
        APP_URL = "https://${localHost}";
        # recipes format dates in this zone; ical events arrive in mixed offsets
        APP_TIMEZONE = "Europe/Berlin";
        DB_CONNECTION = "sqlite";
        DB_DATABASE = "${dataDir}/database/database.sqlite";
        LOG_CHANNEL = "stderr";
        TRUSTED_PROXIES = "127.0.0.1";
        # single user; an account can make the server fetch any url with any headers
        REGISTRATION_ENABLED = "false";
        HOME = dataDir;
        PUPPETEER_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
        # passes --no-sandbox; serviceDefaults confines chromium instead
        PUPPETEER_DOCKER = "true";
      };
      # browsershot runs `node` from PATH
      path = [ pkgs.nodejs ];
      serviceDefaults = {
        User = user;
        Group = user;
        EnvironmentFile = secretEnv;
        WorkingDirectory = package;

        CapabilityBoundingSet = "";
        LockPersonality = true;
        # v8 jit
        MemoryDenyWriteExecute = false;
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
        ProtectSystem = "strict";
        ReadWritePaths = [ dataDir ];
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          # chromium's network change notifier
          "AF_NETLINK"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        # v8 uses memory protection keys; crashpad's ptrace gets EPERM instead of a kill
        SystemCallFilter = [
          "@system-service"
          "pkey_alloc"
          "pkey_free"
          "pkey_mprotect"
        ];
        SystemCallErrorNumber = "EPERM";
        UMask = "0027";
      };
    in
    {
      config = {
        clan.core.vars.generators.larapaper = {
          files."secret.env".owner = user;
          runtimeInputs = [ pkgs.openssl ];
          script = ''
            echo "APP_KEY=base64:$(openssl rand -base64 32)" > "$out/secret.env"
          '';
        };

        users.groups.${user} = { };
        users.users.${user} = {
          isSystemUser = true;
          group = user;
          home = dataDir;
        };
        # caddy serves the generated device images from storage/app/public
        users.users.${config.services.caddy.user}.extraGroups = [ user ];

        systemd.tmpfiles.settings.larapaper =
          lib.genAttrs
            [
              dataDir
              "${dataDir}/cache"
              "${dataDir}/database"
              "${dataDir}/storage"
              "${dataDir}/storage/app"
              "${dataDir}/storage/app/private"
              "${dataDir}/storage/app/public"
              "${dataDir}/storage/framework"
              "${dataDir}/storage/framework/cache"
              "${dataDir}/storage/framework/sessions"
              "${dataDir}/storage/framework/views"
              "${dataDir}/storage/logs"
            ]
            (_: {
              d = {
                inherit user;
                group = user;
                mode = "0750";
              };
            });

        systemd.services.larapaper-setup = {
          description = "LaraPaper database migrations";
          wantedBy = [ "multi-user.target" ];
          before = [
            "phpfpm-larapaper.service"
            "larapaper-queue.service"
            "larapaper-scheduler.service"
          ];
          after = [ "systemd-tmpfiles-setup.service" ];
          inherit environment;
          script = ''
            touch ${environment.DB_DATABASE}
            ${artisan} migrate --force
          '';
          serviceConfig = serviceDefaults // {
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };

        services.phpfpm.pools.larapaper = {
          inherit user;
          group = user;
          phpPackage = php;
          settings = {
            "listen.owner" = config.services.caddy.user;
            "listen.group" = config.services.caddy.group;
            "pm" = "dynamic";
            "pm.max_children" = 8;
            "pm.start_servers" = 2;
            "pm.min_spare_servers" = 1;
            "pm.max_spare_servers" = 4;
            # keep the systemd environment, including APP_KEY
            "clear_env" = "no";
            # LOG_CHANNEL=stderr; without this php-fpm drops render errors
            "catch_workers_output" = "yes";
            "decorate_workers_output" = "no";
          };
        };
        systemd.services.phpfpm-larapaper = {
          requires = [ "larapaper-setup.service" ];
          after = [ "larapaper-setup.service" ];
          inherit environment path;
          serviceConfig.EnvironmentFile = secretEnv;
        };

        systemd.services.larapaper-queue = {
          description = "LaraPaper queue worker";
          wantedBy = [ "multi-user.target" ];
          requires = [ "larapaper-setup.service" ];
          after = [ "larapaper-setup.service" ];
          inherit environment path;
          serviceConfig = serviceDefaults // {
            ExecStart = "${artisan} queue:work --sleep=3 --tries=3";
            Restart = "always";
          };
        };

        systemd.services.larapaper-scheduler = {
          description = "LaraPaper scheduler";
          wantedBy = [ "multi-user.target" ];
          requires = [ "larapaper-setup.service" ];
          after = [ "larapaper-setup.service" ];
          inherit environment path;
          serviceConfig = serviceDefaults // {
            ExecStart = "${artisan} schedule:work";
            Restart = "always";
          };
        };

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          root * ${package}/public
          php_fastcgi unix/${socket}
          file_server
        '';

        services.homepage-dashboard.services = [
          {
            "tools" = [
              {
                "TRMNL" = {
                  href = "https://${localHost}";
                  icon = "sh-trmnl";
                  siteMonitor = "https://${localHost}/up";
                };
              }
            ];
          }
        ];

        services.gatus.settings.endpoints = [
          {
            name = "TRMNL";
            url = "https://${localHost}/up";
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          {
            directory = dataDir;
            inherit user;
            group = user;
          }
        ];
      };
    };
}
