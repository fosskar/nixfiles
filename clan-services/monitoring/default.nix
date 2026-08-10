{ self }:
let
  logsPort = 9428;

  addressOf =
    config: machine:
    if machine == config.networking.hostName then
      "127.0.0.1"
    else
      "${machine}.${config.clan.core.settings.domain}";

  logsUrl =
    config: machine: "http://${addressOf config machine}:${toString logsPort}/insert/journald";
in
{
  _class = "clan.service";
  manifest.name = "monitoring";
  manifest.description = "lightweight central monitoring via telegraf, victoriametrics, victorialogs, and grafana";
  manifest.readme = builtins.readFile ./README.md;

  manifest.constraints.roles.server = {
    minMachines = 1;
    maxMachines = 1;
  };

  roles.server = {
    description = "central monitoring server";

    interface =
      { lib, ... }:
      {
        options = {
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
            clientMachines = lib.attrNames (roles.client.machines or { });

            clientScrapeConfigs = map (
              machine:
              let
                clientSettings = roles.client.machines.${machine}.settings;
                host = if clientSettings.host != null then clientSettings.host else addressOf config machine;
              in
              {
                job_name = "telegraf-${machine}";
                static_configs = [
                  {
                    targets = [ "${host}:${toString clientSettings.listenPort}" ];
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

            dashboardEnabled = {
              "ups.json" = config.power.ups.enable && (config.power.ups.upsd.enable or false);
            };
            dashboardFiles = lib.filter (file: dashboardEnabled.${file} or true) (
              builtins.attrNames (builtins.readDir ./dashboards)
            );
            mkDashboard = file: {
              name = "grafana-dashboards/${file}";
              value.source = "${./dashboards}/${file}";
            };
          in
          {
            # server-only modules; telegraf comes via client role (all server-tagged machines)
            imports = [
              self.modules.nixos.exporter
              self.modules.nixos.grafana
              self.modules.nixos.journaldUpload
              self.modules.nixos.victoriaLogs
              self.modules.nixos.victoriaMetrics
            ];

            assertions = [
              {
                assertion = lib.elem config.networking.hostName clientMachines;
                message = "monitoring: the server machine must also hold the client role";
              }
            ];

            services.grafana.enable = lib.mkDefault true;
            services.victorialogs.enable = lib.mkDefault true;
            services.victorialogs.listenAddress = "0.0.0.0:${toString logsPort}";
            services.victoriametrics.enable = lib.mkDefault true;
            services.telegraf.enable = lib.mkDefault true;

            networking.firewall.interfaces.ygg.allowedTCPPorts = [ logsPort ];

            environment.etc = lib.mkIf config.services.grafana.enable (
              builtins.listToAttrs (map mkDashboard dashboardFiles)
            );

            services.prometheus.exporters.node.enable = lib.mkDefault settings.exporter.node.enable;
            services.prometheus.exporters.zfs.enable = lib.mkDefault (
              settings.exporter.zfs.enable && (config.boot.supportedFilesystems.zfs or false)
            );

            services.victoriametrics = {
              retentionPeriod = lib.mkDefault settings.retentionPeriod;
              prometheusConfig.scrape_configs = lib.mkAfter (clientScrapeConfigs ++ extraTelegrafScrapeConfig);
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
              self.modules.nixos.journaldUpload
              self.modules.nixos.telegraf
            ];

            networking.firewall.interfaces.ygg.allowedTCPPorts = lib.mkIf (
              !(builtins.elem config.networking.hostName serverMachines)
            ) [ settings.listenPort ];

            services.journald.upload = {
              enable = lib.mkDefault true;
              settings.Upload.URL = lib.mkDefault (logsUrl config (builtins.head serverMachines));
            };

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
