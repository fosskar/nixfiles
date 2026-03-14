_: {
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

          dashboardsDir = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "grafana dashboards directory for provisioning";
          };

          exporter.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "enable local prometheus exporters on monitoring server";
          };

          exporter.enableZfsExporter = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "enable zfs exporter on monitoring server";
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
            pkgs,
            ...
          }:
          let
            clientMachines = lib.attrNames (roles.client.machines or { });

            clientScrapeConfigs = map (
              machine:
              let
                clientSettings = (roles.client.machines.${machine} or { }).settings or { };
                port = clientSettings.listenPort or 9273;
                host =
                  if (clientSettings.host or null) != null then
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
            ) (builtins.filter (machine: machine != config.networking.hostName) clientMachines);

            extraTelegrafScrapeConfig = lib.optional (settings.extraTelegrafTargets != [ ]) {
              job_name = "openwrt-telegraf";
              static_configs = [
                {
                  targets = settings.extraTelegrafTargets;
                  labels = {
                    type = "telegraf";
                    source = "external";
                  };
                }
              ];
            };

            serviceDashboardsDir =
              if settings.dashboardsDir == null then
                ./dashboards
              else
                pkgs.symlinkJoin {
                  name = "monitoring-dashboards";
                  paths = [
                    ./dashboards
                    settings.dashboardsDir
                  ];
                };
          in
          {
            imports = [ ../../modules/monitoring ];

            nixfiles.monitoring = {
              grafana = {
                enable = lib.mkDefault settings.grafana.enable;
                dashboardsDir = lib.mkDefault serviceDashboardsDir;
              };

              exporter = {
                enable = lib.mkDefault settings.exporter.enable;
                enableZfsExporter = lib.mkDefault settings.exporter.enableZfsExporter;
              };

              victorialogs.enable = lib.mkDefault true;

              victoriametrics = {
                enable = lib.mkDefault true;
                retentionPeriod = lib.mkDefault settings.retentionPeriod;
                scrapeConfigs = lib.mkAfter (
                  clientScrapeConfigs ++ extraTelegrafScrapeConfig ++ settings.extraScrapeConfigs
                );
              };

              telegraf.enable = lib.mkDefault true;
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

          plugins = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "system"
              "systemd"
            ];
            description = "telegraf input plugins";
          };

          vector.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "enable vector shipper on this client";
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
      in
      {
        nixosModule =
          {
            config,
            lib,
            ...
          }:
          {
            imports = [
              ../../modules/monitoring/telegraf.nix
              ../../modules/monitoring/vector.nix
            ];

            networking.firewall.interfaces.ygg.allowedTCPPorts = lib.mkIf (
              !(builtins.elem config.networking.hostName serverMachines)
            ) [ settings.listenPort ];

            nixfiles.monitoring.telegraf = {
              enable = lib.mkDefault true;
              listenPort = lib.mkDefault settings.listenPort;
              plugins = lib.mkDefault settings.plugins;
            };

            nixfiles.monitoring.vector.enable = lib.mkDefault settings.vector.enable;

          };
      };
  };
}
