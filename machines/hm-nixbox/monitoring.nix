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

  nixfiles.monitoring = {
    grafana.dashboardsDir = ./dashboards;

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
    victoriametrics.scrapeConfigs = [
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
}
