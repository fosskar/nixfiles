{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../modules/monitoring
  ];

  # machine-specific beszel agent config
  systemd.services.beszel-agent = {
    unitConfig.RequiresMountsFor = [ "/tank" ];
    serviceConfig = {
      AmbientCapabilities = "CAP_SYS_RAWIO CAP_SYS_ADMIN";
      CapabilityBoundingSet = "CAP_SYS_RAWIO CAP_SYS_ADMIN";
      SupplementaryGroups = [ "disk" ];
      PrivateUsers = lib.mkForce false;
      NoNewPrivileges = lib.mkForce false;
    };
  };

  services.beszel.agent = {
    enable = true;
    environment = {
      LISTEN = "45876";
      SENSORS = "-nct6798_cputin,-nct6798_auxtin0,-nct6798_auxtin2,-nct6798_auxtin4";
      FILESYSTEM = "/persist";
      EXTRA_FILESYSTEMS = "/nix__Nix,/tank/apps__Apps,/tank/media__Media,/tank/shares__Shares,/tank/backup__Backup";
    };
    environmentFile = config.sops.secrets."beszel.env".path;
    extraPath = [
      pkgs.intel-gpu-tools
      pkgs.smartmontools
    ];
  };

  # machine-specific scrape targets
  nixfiles.monitoring.victoriametrics.scrapeConfigs = [
    {
      job_name = "node-exporter";
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
      job_name = "telegraf";
      static_configs = [
        {
          targets = [ "localhost:9273" ];
          labels.type = "telegraf";
        }
      ];
    }
    {
      job_name = "zfs-exporter";
      static_configs = [
        { targets = [ "localhost:9134" ]; }
      ];
    }
    {
      job_name = "victoriametrics";
      static_configs = [
        { targets = [ "localhost:8428" ]; }
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

  monitoring.telegraf = {
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

  monitoring.exporter = {
    enable = true;
    enableZfsExporter = true;
  };

  environment.systemPackages = [ pkgs.nut ];

  # provision grafana dashboards via /etc
  environment.etc = builtins.listToAttrs (
    map (file: {
      name = "grafana-dashboards/${file}";
      value.source = ./dashboards/${file};
    }) (builtins.attrNames (builtins.readDir ./dashboards))
  );

  # machine-specific grafana provisioning
  services.grafana.provision = {
    enable = true;

    datasources.settings.datasources = [
      {
        name = "VictoriaMetrics";
        type = "prometheus";
        access = "proxy";
        url = "http://localhost:8428";
        isDefault = true;
      }
      {
        name = "VictoriaLogs";
        type = "victoriametrics-logs-datasource";
        access = "proxy";
        url = "http://localhost:9428";
      }
    ];

    dashboards.settings = {
      apiVersion = 1;
      providers = [
        {
          name = "nixos";
          orgId = 1;
          type = "file";
          disableDeletion = true;
          editable = true;
          options.path = "/etc/grafana-dashboards";
        }
      ];
    };
  };
}
