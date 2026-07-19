{
  flake.modules.nixos.opensoho =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "opensoho";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8091;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      services.homepage-dashboard.services = [
        {
          "network" = [
            {
              "OpenSOHO" = {
                href = "https://${localHost}";
                icon = "mdi-router-wireless";
                siteMonitor = "${listenUrl}/api/health";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "OpenSOHO";
          url = "https://${localHost}/api/health";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';

      # shared secret lets openwisp-config on the openwrt devices self-register
      clan.core.vars.generators.opensoho = {
        files."opensoho.env".restartUnits = [ "opensoho.service" ];
        runtimeInputs = [ pkgs.pwgen ];
        script = ''
          echo "OPENSOHO_SHARED_SECRET=$(pwgen -s 64 1)" > "$out/opensoho.env"
        '';
      };

      systemd.services.opensoho = {
        description = "OpenSOHO OpenWRT controller";
        documentation = [ "https://github.com/rubenbe/opensoho" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          # pb_data and extracted pb_migrations live relative to cwd
          ExecStart = "${lib.getExe pkgs.local.opensoho} serve --http ${listenAddress}:${toString listenPort}";
          WorkingDirectory = "/var/lib/opensoho";
          StateDirectory = "opensoho";
          StateDirectoryMode = "0750";
          EnvironmentFile = [ config.clan.core.vars.generators.opensoho.files."opensoho.env".path ];
          Restart = "on-failure";
          RestartSec = 5;

          # hardening
          DynamicUser = true;
          CapabilityBoundingSet = "";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";
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
    };
}
