{
  flake.modules.nixos =
    let
      inputConfigs = {
        system = {
          cpu = [
            {
              percpu = true;
              totalcpu = true;
            }
          ];
          mem = [ { } ];
          disk = [ { } ];
          diskio = [ { } ];
          net = [ { } ];
          system = [ { } ];
          processes = [ { } ];
        };
        zfs = {
          zfs = [
            {
              poolMetrics = true;
              kstatMetrics = [
                "abdstats"
                "arcstats"
                "dbufcachestats"
                "dnodestats"
                "dmu_tx"
                "fm"
                "vdev_mirror_stats"
                "zfetchstats"
                "zil"
              ];
            }
          ];
        };
        upsd = {
          upsd = [
            {
              server = "127.0.0.1";
              port = 3493;
            }
          ];
        };
        systemd = {
          systemd_units = [ { } ];
        };
        sensors = {
          sensors = [ { } ];
        };
        smart = {
          smart = [
            {
              use_sudo = true;
              attributes = true;
              nocheck = "standby"; # skip disks in standby (default, won't wake sleeping disks)
            }
          ];
        };
        docker = {
          docker = [
            {
              endpoint = "unix:///var/run/docker.sock";
              gather_services = false;
              perdevice = true;
              total = true;
            }
          ];
        };
        postgresql = {
          postgresql = [
            {
              address = "host=/run/postgresql user=telegraf dbname=postgres sslmode=disable";
            }
          ];
        };
        redis = {
          redis = [
            {
              servers = [ "tcp://127.0.0.1:6379" ];
            }
          ];
        };
        x509_cert = {
          x509_cert = [
            {
              sources = [ "https://nx3.eu:443" ];
              timeout = "5s";
            }
          ];
        };
      };
    in
    {
      telegraf =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        lib.mkIf config.services.telegraf.enable {
          services.telegraf = {
            package = pkgs.telegraf;
            extraConfig = {
              agent = {
                interval = "10s";
                flush_interval = "10s";
              };

              outputs.prometheus_client = lib.mkDefault [
                {
                  listen = ":9273";
                  metric_version = 2;
                }
              ];
            };
          };
        };

      telegrafSystem =
        { config, lib, ... }:
        {
          services.telegraf.extraConfig.inputs = lib.mkIf config.services.telegraf.enable inputConfigs.system;
        };

      telegrafSystemd =
        { config, lib, ... }:
        {
          services.telegraf.extraConfig.inputs = lib.mkIf config.services.telegraf.enable inputConfigs.systemd;
        };

      telegrafZfs =
        { config, lib, ... }:
        {
          services.telegraf.extraConfig.inputs = lib.mkIf config.services.telegraf.enable inputConfigs.zfs;
        };

      telegrafUpsd =
        { config, lib, ... }:
        {
          services.telegraf.extraConfig.inputs = lib.mkIf config.services.telegraf.enable inputConfigs.upsd;
        };

      telegrafSensors =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        lib.mkIf config.services.telegraf.enable {
          services.telegraf.extraConfig.inputs = inputConfigs.sensors;
          systemd.services.telegraf.path = [ pkgs.lm_sensors ];
        };

      telegrafSmart =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        lib.mkIf config.services.telegraf.enable {
          services.telegraf.extraConfig.inputs = inputConfigs.smart;

          services.udev.extraRules = ''
            KERNEL=="nvme[0-9]*", GROUP="disk", MODE="0660"
          '';

          systemd.services.telegraf.path = [
            "/run/wrappers" # for sudo
            pkgs.smartmontools
            pkgs.nvme-cli
          ];

          users.users.telegraf.extraGroups = [
            "disk"
            "wheel"
          ];

          security.sudo-rs.extraRules = [
            {
              users = [ "telegraf" ];
              commands = [
                {
                  command = "${pkgs.smartmontools}/bin/smartctl";
                  options = [ "NOPASSWD" ];
                }
                {
                  command = "${pkgs.nvme-cli}/bin/nvme";
                  options = [ "NOPASSWD" ];
                }
              ];
            }
          ];
        };

      telegrafDocker =
        { config, lib, ... }:
        lib.mkIf config.services.telegraf.enable {
          services.telegraf.extraConfig.inputs = inputConfigs.docker;
          users.users.telegraf.extraGroups = [ "docker" ];
        };

      telegrafPostgresql =
        { config, lib, ... }:
        lib.mkIf config.services.telegraf.enable {
          services.telegraf.extraConfig.inputs = inputConfigs.postgresql;
          services.postgresql.ensureUsers = [
            {
              name = "telegraf";
              ensureDBOwnership = false;
            }
          ];
        };

      telegrafRedis =
        { config, lib, ... }:
        {
          services.telegraf.extraConfig.inputs = lib.mkIf config.services.telegraf.enable inputConfigs.redis;
        };

      telegrafX509Cert =
        { config, lib, ... }:
        {
          services.telegraf.extraConfig.inputs = lib.mkIf config.services.telegraf.enable inputConfigs.x509_cert;
        };
    };
}
