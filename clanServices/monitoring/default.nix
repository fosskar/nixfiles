{ self }:
{
  _class = "clan.service";
  manifest.name = "monitoring";
  manifest.description = "lightweight central monitoring via telegraf, victoriametrics, victorialogs, and grafana";
  manifest.readme = "opinionated lightweight monitoring service for nixfiles";

  roles.server = {
    description = "central monitoring server";

    interface =
      { lib, ... }:
      {
        options = {
          grafana.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "enable grafana on monitoring server";
          };

          retentionPeriod = lib.mkOption {
            type = lib.types.str;
            default = "3";
            description = "victoriametrics retention in months";
          };

          extraTelegrafTargets = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "extra telegraf prometheus endpoints (host:port), including non-clan hosts";
            example = [
              "192.168.10.1:9273"
            ];
          };

          extraScrapeConfigs = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
            description = "extra victoriametrics scrape configs";
          };

          extraDashboardsDir = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "extra grafana dashboards directory for provisioning";
          };

          exporter.node.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "enable node exporter on monitoring server";
          };

          exporter.zfs.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "enable zfs exporter on monitoring server when zfs is enabled";
          };
        };
      };

    perInstance =
      {
        roles,
        settings,
        ...
      }:
      {
        nixosModule =
          {
            config,
            lib,
            ...
          }:
          let
            serverMachines = lib.attrNames (roles.server.machines or { });
            serverMachineCount = lib.length serverMachines;
            clientMachines = lib.attrNames (roles.client.machines or { });

            clientScrapeConfigs = map (
              machine:
              let
                clientSettings = (roles.client.machines.${machine} or { }).settings or { };
                port = clientSettings.listenPort or 9273;
                host =
                  if machine == config.networking.hostName then
                    "127.0.0.1"
                  else if (clientSettings.host or null) != null then
                    clientSettings.host
                  else
                    "${machine}.${config.clan.core.settings.domain}";
              in
              {
                job_name = "telegraf-${machine}";
                static_configs = [
                  {
                    targets = [ "${host}:${toString port}" ];
                    labels = {
                      type = "telegraf";
                      inherit machine;
                      source = "clan";
                    };
                  }
                ];
              }
            ) clientMachines;

            targetMachine = target: lib.head (lib.splitString "." (lib.head (lib.splitString ":" target)));
            extraTelegrafScrapeConfig = lib.optional (settings.extraTelegrafTargets != [ ]) {
              job_name = "external-telegraf";
              static_configs = map (target: {
                targets = [ target ];
                labels = {
                  type = "telegraf";
                  source = "external";
                  target = targetMachine target;
                };
              }) settings.extraTelegrafTargets;
            };

            baseDashboardsDir = ./dashboards;
            dashboardEnabled = {
              "ups.json" = config.power.ups.enable && (config.power.ups.upsd.enable or false);
            };
            baseDashboardFiles = lib.filter (file: dashboardEnabled.${file} or true) (
              builtins.attrNames (builtins.readDir baseDashboardsDir)
            );
            extraDashboardFiles = lib.optionals (settings.extraDashboardsDir != null) (
              builtins.attrNames (builtins.readDir settings.extraDashboardsDir)
            );
            mkDashboard = dir: file: {
              name = "grafana-dashboards/${file}";
              value.source = "${dir}/${file}";
            };
          in
          {
            # server-only modules; telegraf comes via client role (all server-tagged machines)
            imports = with self.modules.nixos; [
              exporter
              grafana
              victoriaLogs
              victoriaMetrics
            ];

            assertions = [
              {
                assertion = serverMachineCount == 1;
                message = "monitoring requires exactly one server machine, got ${toString serverMachineCount}";
              }
            ];

            services.grafana.enable = lib.mkDefault settings.grafana.enable;
            services.victorialogs.enable = lib.mkDefault true;
            services.victoriametrics.enable = lib.mkDefault true;
            services.telegraf.enable = lib.mkDefault true;

            environment.etc = lib.mkIf config.services.grafana.enable (
              builtins.listToAttrs (
                (map (mkDashboard baseDashboardsDir) baseDashboardFiles)
                ++ (map (mkDashboard settings.extraDashboardsDir) extraDashboardFiles)
              )
            );

            services.prometheus.exporters.node.enable = lib.mkDefault settings.exporter.node.enable;
            services.prometheus.exporters.zfs.enable = lib.mkDefault (
              settings.exporter.zfs.enable && (config.boot.supportedFilesystems.zfs or false)
            );

            services.victoriametrics = {
              retentionPeriod = lib.mkDefault settings.retentionPeriod;
              prometheusConfig.scrape_configs = lib.mkAfter (
                clientScrapeConfigs ++ extraTelegrafScrapeConfig ++ settings.extraScrapeConfigs
              );
            };
          };
      };
  };

  roles.client = {
    description = "monitoring client exposing telegraf metrics";

    interface =
      { lib, ... }:
      {
        options = {
          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 9273;
            description = "telegraf prometheus_client listen port";
          };

          host = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "override scrape host for this client (default: <machine>.<clan-domain>)";
          };

        };
      };

    perInstance =
      {
        settings,
        roles,
        ...
      }:
      let
        serverMachines = builtins.attrNames (roles.server.machines or { });
        serverMachineCount = builtins.length serverMachines;
      in
      {
        nixosModule =
          {
            config,
            lib,
            ...
          }:
          {
            imports = with self.modules.nixos; [
              telegraf
            ];

            assertions = [
              {
                assertion = serverMachineCount == 1;
                message = "monitoring requires exactly one server machine, got ${toString serverMachineCount}";
              }
            ];

            networking.firewall.interfaces.ygg.allowedTCPPorts = lib.mkIf (
              !(builtins.elem config.networking.hostName serverMachines)
            ) [ settings.listenPort ];

            services.telegraf = {
              enable = lib.mkDefault true;
              extraConfig.outputs.prometheus_client = lib.mkForce [
                {
                  listen = ":${toString settings.listenPort}";
                  metric_version = 2;
                }
              ];
            };
          };
      };
  };
}
