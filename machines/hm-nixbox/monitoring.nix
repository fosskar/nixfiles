{
  config,
  ...
}:
let
  gotifyPort = config.nixfiles.notify.gotify.port;
  gotifyTokenFile = config.nixfiles.notify.gotify.tokenFile.grafana;
in
{
  imports = [
    ../../modules/monitoring
  ];

  # machine-specific beszel config
  systemd.services.beszel-agent.unitConfig.RequiresMountsFor = [ "/tank" ];

  services.beszel.agent.environmentFile = config.sops.secrets."beszel.env".path;

  # remove old grafana datasources
  services.grafana.provision.datasources.settings.deleteDatasources = [
  ];

  # grafana alerting -> gotify
  services.grafana.provision.alerting.contactPoints.settings = {
    apiVersion = 1;
    contactPoints = [
      {
        orgId = 1;
        name = "gotify";
        receivers = [
          {
            uid = "gotify";
            type = "webhook";
            settings = {
              url = "http://127.0.0.1:${toString gotifyPort}/message?token=$__file{${gotifyTokenFile}}";
            };
          }
        ];
      }
    ];
  };

  nixfiles.monitoring = {
    beszel = {
      hub.enable = true;
      agent = {
        enable = true;
        sensors = "-nct6798_cputin,-nct6798_auxtin0,-nct6798_auxtin2,-nct6798_auxtin4";
        filesystem = "/persist";
        extraFilesystems = "/nix__Nix,/tank/apps__Apps,/tank/media__Media,/tank/shares__Shares,/tank/backup__Backup";
      };
    };

    netdata.enable = true;

    grafana = {
      enable = true;
      dashboardsDir = ./dashboards;
    };

    telegraf = {
      enable = true;
      plugins = [
        "system"
        "systemd"
        "zfs"
        "upsd"
        "sensors"
        "smart"
        "postgresql"
      ];
    };

    exporter = {
      enable = true;
      enableZfsExporter = true;
    };

    victoriametrics = {
      enable = true;
      scrapeConfigs = [
        {
          job_name = "openwrt-node-exporter";
          static_configs = [
            {
              targets = [
                "192.168.10.1:9100"
                "192.168.10.2:9100"
              ];
              labels.type = "node-exporter";
            }
          ];
        }
        {
          job_name = "openwrt-telegraf";
          static_configs = [
            {
              targets = [ "192.168.10.1:9273" ];
              labels.type = "telegraf";
            }
          ];
        }
      ];
    };
  };
}
