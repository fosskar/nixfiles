{
  flake.modules.nixos.sprout-track =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "sprout-track";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8024;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      stateDir = "/var/lib/sprout-track";
    in
    {
      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              "Sprout Track" = {
                href = "https://${localHost}";
                icon = "mdi-sprout";
                siteMonitor = listenUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Sprout Track";
          url = "https://${localHost}/";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';

      clan.core.vars.generators.sprout-track = {
        files."sprout-track.env".restartUnits = [ "sprout-track.service" ];
        runtimeInputs = [ pkgs.openssl ];
        script = ''
          {
            echo "JWT_SECRET=$(openssl rand -hex 32)"
            echo "ENC_HASH=$(openssl rand -hex 32)"
          } > "$out/sprout-track.env"
        '';
      };

      clan.core.vars.generators.sprout-track-notification-cron = {
        files."notification-cron.env".restartUnits = [ "sprout-track.service" ];
        runtimeInputs = [ pkgs.openssl ];
        script = ''
          echo "NOTIFICATION_CRON_SECRET=$(openssl rand -hex 32)" > "$out/notification-cron.env"
        '';
      };

      # consistent sqlite snapshot into /var/backup for the borg backup;
      # the live files under /var/lib can be captured mid-write otherwise
      clan.core.state.sprout-track = {
        folders = [ "/var/backup/sprout-track" ];
        preBackupScript = ''
          export PATH=${
            lib.makeBinPath [
              pkgs.sqlite
              pkgs.coreutils
            ]
          }
          mkdir -p /var/backup/sprout-track
          sqlite3 ${stateDir}/db/baby-tracker.db ".backup '/var/backup/sprout-track/baby-tracker.db'"
          sqlite3 ${stateDir}/db/api-logs.db ".backup '/var/backup/sprout-track/api-logs.db'"
        '';
      };

      systemd.services.sprout-track = {
        description = "Sprout Track baby tracker";
        documentation = [ "https://github.com/Oak-and-Sprout/sprout-track" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStartPre = [
            # db and Files are symlinks to this state dir; create the subdirs
            # before prisma migrate writes into them
            "${pkgs.coreutils}/bin/mkdir -p ${stateDir}/db ${stateDir}/Files"
            "${pkgs.local.sprout-track}/bin/sprout-track-prisma migrate deploy"
            "${pkgs.local.sprout-track}/bin/sprout-track-prisma db push --schema=prisma/log-schema.prisma --skip-generate"
            "${pkgs.local.sprout-track}/bin/sprout-track-prisma db seed"
          ];
          ExecStart = "${lib.getExe pkgs.local.sprout-track} --hostname ${listenAddress} --port ${toString listenPort}";
          StateDirectory = "sprout-track";
          StateDirectoryMode = "0750";
          CacheDirectory = "sprout-track";
          CacheDirectoryMode = "0750";
          EnvironmentFile = [
            config.clan.core.vars.generators.sprout-track.files."sprout-track.env".path
            config.clan.core.vars.generators.sprout-track-notification-cron.files."notification-cron.env".path
          ];
          Environment = [
            "NODE_ENV=production"
            "TZ=Europe/Berlin"
            "DATABASE_URL=file:${stateDir}/db/baby-tracker.db"
            "LOG_DATABASE_URL=file:${stateDir}/db/api-logs.db"
            "COOKIE_SECURE=true"
            "APP_URL=https://${localHost}"
            "ENABLE_NOTIFICATIONS=true"
          ];
          Restart = "on-failure";
          RestartSec = 5;

          # hardening (no MemoryDenyWriteExecute: node's v8 jit needs w+x)
          DynamicUser = true;
          CapabilityBoundingSet = "";
          LockPersonality = true;
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
          ProtectSystem = "strict";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          UMask = "0077";
        };
      };

      # notification timer check: upstream runs a per-minute crond entry in the
      # container; here the same work is a systemd timer + oneshot. it curls
      # the cron endpoints, so it needs curl and CA certs on top of the secret.
      systemd.services.sprout-track-notification-cron = {
        description = "Sprout Track notification timer check";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.curl ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash ${pkgs.local.sprout-track}/libexec/sprout-track/scripts/run-notification-cron.sh";
          EnvironmentFile = [
            config.clan.core.vars.generators.sprout-track-notification-cron.files."notification-cron.env".path
          ];
          Environment = [
            "APP_URL=https://${localHost}"
            "NODE_ENV=production"
            "TZ=Europe/Berlin"
            "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
          ];

          # hardening (oneshot curl; no state)
          DynamicUser = true;
          CapabilityBoundingSet = "";
          LockPersonality = true;
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
          ProtectSystem = "strict";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          UMask = "0077";
        };
      };

      systemd.timers.sprout-track-notification-cron = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "minutely";
          AccuracySec = "5s";
        };
      };
    };
}
