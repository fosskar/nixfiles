{
  flake.modules.nixos.silo =
    {
      flake-self,
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      serviceName = "silo";
      localHost = "${serviceName}.${flake-self.domains.local}";
      # silo binds every port to all interfaces; the firewall stays closed
      listenPort = 8190;
      listenUrl = "http://127.0.0.1:${toString listenPort}";
      dataDir = "/var/lib/silo";
      mediaRoot = "/tank/media";
      redis = config.services.redis.servers.silo;
    in
    {
      config = {
        # --- service ---

        clan.core.vars.generators.silo = {
          files."secret.env" = { };

          runtimeInputs = [ pkgs.pwgen ];
          script = ''
            echo "SECRET_KEY=$(pwgen -s 64 1)" > "$out/secret.env"
          '';
        };

        users.groups = {
          silo = { };
          media = { };
        };
        users.users.silo = {
          isSystemUser = true;
          group = "silo";
          home = dataDir;
          extraGroups = [
            "media"
            "render"
            "video"
            redis.group
          ];
        };

        services.redis.servers.silo.enable = true;

        systemd.services.silo = {
          description = "silo media server";
          after = [
            "network-online.target"
            "postgresql.service"
            "redis-silo.service"
            "silo-postgresql-extensions.service"
          ];
          wants = [ "network-online.target" ];
          requires = [
            "postgresql.service"
            "redis-silo.service"
            "silo-postgresql-extensions.service"
          ];
          wantedBy = [ "multi-user.target" ];
          # silo marks files missing when it scans an unmounted library
          unitConfig.RequiresMountsFor = [ mediaRoot ];
          # backups run pg_dump
          path = [ config.services.postgresql.package ];
          environment = {
            PORT = toString listenPort;
            # jellyfin has 8096 and audiobookshelf 13378
            JF_PORT = "8196";
            ABS_PORT = "13379";
            DATABASE_URL = "postgres://silo@/silo?host=/run/postgresql&sslmode=disable";
            REDIS_URL = "unix://${redis.unixSocket}";
            SILO_PLUGIN_CACHE_DIR = "${dataDir}/plugins";
            HOME = dataDir;
          };
          serviceConfig = {
            User = "silo";
            Group = "silo";
            StateDirectory = "silo";
            WorkingDirectory = dataDir;
            EnvironmentFile = config.clan.core.vars.generators.silo.files."secret.env".path;
            ExecStart = lib.getExe pkgs.local.silo-server;
            Restart = "on-failure";
            # transcodes go to /tmp/silo-transcode
            PrivateTmp = true;
          };
        };

        # --- database ---

        services.postgresql.extensions = ps: [ ps.pgvector ];

        clan.core.postgresql.enable = true;
        clan.core.postgresql.users.silo = { };
        clan.core.postgresql.databases.silo = {
          create.options.OWNER = "silo";
          restore.stopOnRestore = [ "silo.service" ];
        };

        # pgvector is not a trusted extension, so the database owner cannot
        # create it in the migrations
        systemd.services.silo-postgresql-extensions = {
          description = "create the pgvector extension for silo";
          after = [ "postgresql.service" ];
          requires = [ "postgresql.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "postgres";
            ExecStart = "${lib.getExe' config.services.postgresql.package "psql"} -d silo -c 'CREATE EXTENSION IF NOT EXISTS vector'";
          };
        };

        # --- homepage ---

        services.homepage-dashboard.services = [
          {
            "media" = [
              {
                "Silo" = {
                  href = "https://${localHost}";
                  icon = "mdi-silo";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "Silo";
            url = "https://${localHost}";
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        # --- caddy ---

        # no proxy-auth - silo has built-in auth
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl} {
            flush_interval -1
          }
        '';
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          {
            directory = dataDir;
            user = "silo";
            group = "silo";
          }
        ];
      };
    };
}
