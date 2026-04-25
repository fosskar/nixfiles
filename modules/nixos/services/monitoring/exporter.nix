{
  flake.modules.nixos.exporter = {
    services.prometheus.exporters = {
      node = {
        port = 9100;
        openFirewall = false;
        enabledCollectors = [
          "systemd"
          "processes"
        ];
      };

      nginx = {
        port = 9113;
        openFirewall = false;
        scrapeUri = "http://127.0.0.1:80/nginx_status";
      };

      postgres = {
        port = 9187;
        openFirewall = false;
        runAsLocalSuperUser = true;
      };

      restic = {
        port = 9753;
        openFirewall = false;
        refreshInterval = 3600;
      };

      nut = {
        port = 9199;
        listenAddress = "127.0.0.1";
        openFirewall = false;
        nutServer = "127.0.0.1";
      };

      zfs = {
        port = 9134;
        openFirewall = false;
      };
    };
  };
}
