{
  config,
  lib,
  ...
}:
let
  cfg = config.nixfiles.monitoring.exporter;
in
{
  options.nixfiles.monitoring.exporter = {
    enable = lib.mkEnableOption "prometheus exporters";

    enableNodeExporter = lib.mkEnableOption "node exporter for system metrics (includes systemd)";

    enableNginxExporter = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable nginx exporter if nginx is running";
    };

    enablePostgresExporter = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable postgres exporter if postgresql is running";
    };

    enableResticExporter = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable restic exporter if restic backups are configured";
    };

    enableNutExporter = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable nut exporter for ups monitoring";
    };

    enableZfsExporter = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable zfs exporter for pool metrics";
    };

    nutServer = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "nut server address";
    };
  };

  config = lib.mkIf cfg.enable {
    # node exporter - system metrics (includes systemd collector)
    services.prometheus.exporters.node = lib.mkIf cfg.enableNodeExporter {
      enable = true;
      port = 9100;
      openFirewall = false;
      enabledCollectors = [
        "systemd" # systemd service metrics
        "processes"
      ];
    };

    # nginx exporter
    services.prometheus.exporters.nginx = lib.mkIf cfg.enableNginxExporter {
      enable = true;
      port = 9113;
      openFirewall = false;
      scrapeUri = "http://127.0.0.1:80/nginx_status";
    };

    # postgres exporter
    services.prometheus.exporters.postgres = lib.mkIf cfg.enablePostgresExporter {
      enable = true;
      port = 9187;
      openFirewall = false;
      runAsLocalSuperUser = true;
    };

    # restic exporter
    services.prometheus.exporters.restic = lib.mkIf cfg.enableResticExporter {
      enable = true;
      port = 9753;
      openFirewall = false;
      refreshInterval = 3600; # 1 hour - restic operations are expensive
    };

    # nut exporter
    services.prometheus.exporters.nut = lib.mkIf cfg.enableNutExporter {
      enable = true;
      port = 9199;
      listenAddress = "127.0.0.1";
      openFirewall = false;
      inherit (cfg) nutServer;
    };

    # zfs exporter
    services.prometheus.exporters.zfs = lib.mkIf cfg.enableZfsExporter {
      enable = true;
      port = 9134;
      openFirewall = false;
    };
  };
}
