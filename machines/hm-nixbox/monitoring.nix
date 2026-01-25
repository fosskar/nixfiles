{
  config,
  ...
}:
{
  imports = [
    ../../modules/monitoring
  ];

  # machine-specific beszel config
  systemd.services.beszel-agent.unitConfig.RequiresMountsFor = [ "/tank" ];

  services.beszel.agent.environmentFile = config.sops.secrets."beszel.env".path;

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
      ];
    };

    exporter = {
      enable = true;
      enableZfsExporter = true;
    };

    # machine-specific remote scrape targets
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
