{
  flake.modules.nixos.artex =
    {
      flake-self,
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      serviceName = "artex";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8790;
      proxyPort = 8791;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      stateDir = "/var/lib/artex";
      package = pkgs.local.artex;
    in
    {
      config = {
        users.users.artex = {
          isSystemUser = true;
          group = "artex";
          home = stateDir;
        };
        users.groups.artex = { };

        systemd.services.artex = {
          description = "ARTEX autonomous penetration testing platform";
          documentation = [ "https://github.com/BaaRai/ARTEX" ];
          after = [
            "network-online.target"
            "postgresql.service"
          ];
          requires = [ "postgresql.service" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];

          environment = {
            # peer auth over the unix socket; the role matches the service user
            ARTEX_PG_DSN = "postgres://artex@/artex?host=/run/postgresql";
            ARTEX_SKILL_DIR = "${stateDir}/skills";
            ARTEX_JWT_KEY_DIR = "${stateDir}/keys";
            ARTEX_TRUSTED_PROXIES = "127.0.0.1";
            HOME = stateDir;
          };

          # built-in skills ship in the store; refresh them on every start and
          # keep skills uploaded through the ui
          preStart = ''
            mkdir -p ${stateDir}/data ${stateDir}/keys ${stateDir}/skills
            cp -r --no-preserve=mode,ownership ${package}/share/artex/skills/. ${stateDir}/skills/
          '';

          serviceConfig = {
            ExecStart = lib.concatStringsSep " " [
              (lib.getExe package)
              "-addr ${listenAddress}:${toString listenPort}"
              "-proxy ${listenAddress}:${toString proxyPort}"
              "-data ${stateDir}/data"
            ];
            User = "artex";
            Group = "artex";
            StateDirectory = "artex";
            StateDirectoryMode = "0700";
            WorkingDirectory = stateDir;
            Restart = "on-failure";
            RestartSec = 5;

            # workers run llm-chosen shell commands; node and chromium need jit
            # and user namespaces, so no MemoryDenyWriteExecute or RestrictNamespaces
            NoNewPrivileges = true;
            PrivateTmp = true;
            PrivateDevices = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            RestrictSUIDSGID = true;
            RestrictRealtime = true;
            LockPersonality = true;
            UMask = "0077";
          };
        };

        clan.core.postgresql.enable = true;
        clan.core.postgresql.users.artex = { };
        clan.core.postgresql.databases.artex = {
          create.enable = true;
          create.options.OWNER = "artex";
          restore.stopOnRestore = [ "artex.service" ];
        };

        services.homepage-dashboard.services = [
          {
            "security" = [
              {
                "ARTEX" = {
                  href = "https://${localHost}";
                  icon = "mdi-shield-search";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        services.gatus.settings.endpoints = [
          {
            name = "ARTEX";
            # backend check on purpose: the edge is forward-auth, authelia answers 302 without reaching the service
            url = "${listenUrl}/api/health";
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy ${listenUrl}
        '';

        # workers run llm-chosen shell commands as the artex user; admins only
        services.authelia.instances.main.settings.access_control.rules =
          lib.mkIf (config.services.authelia.instances.main.enable or false)
            (
              lib.mkBefore [
                {
                  domain = [ localHost ];
                  subject = [ "group:admin" ];
                  policy = "one_factor";
                }
                {
                  domain = [ localHost ];
                  policy = "deny";
                }
              ]
            );
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          {
            directory = stateDir;
            user = "artex";
            group = "artex";
            mode = "0700";
          }
        ];
      };
    };
}
