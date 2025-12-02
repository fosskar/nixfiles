{
  config,
  lib,
  ...
}:
let
  cfg = config.monitoring;
in
{
  options.monitoring = {
    enable = lib.mkEnableOption "monitoring exporters" // {
      default = true;
    };

    enableNodeExporter = lib.mkEnableOption "node exporter for system metrics (includes systemd)" // {
      default = true;
    };

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
      scrapeUri = "http://localhost:80/nginx_status";
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
      nutServer = cfg.nutServer;
    };
  };
}
