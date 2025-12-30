{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.monitoring.telegraf;

  # available input plugins
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
    nginx = {
      nginx = [
        {
          urls = [ "http://127.0.0.1:8009/nginx_status" ];
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
          sources = [ "https://osscar.me:443" ];
          timeout = "5s";
        }
      ];
    };
  };
in
{
  options.nixfiles.monitoring.telegraf = {
    enable = lib.mkEnableOption "telegraf monitoring agent";

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 9273;
      description = "prometheus_client listen port";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (builtins.attrNames inputConfigs));
      default = [
        "system"
        "systemd"
      ];
      description = "list of telegraf plugins to enable";
      example = [
        "system"
        "zfs"
        "upsd"
        "systemd"
        "sensors"
        "smart"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.telegraf = {
      enable = true;

      # add required binaries to telegraf's PATH
      package = pkgs.telegraf;
    };

    systemd.services.telegraf.path = lib.mkMerge [
      (lib.mkIf (builtins.elem "sensors" cfg.plugins) [ pkgs.lm_sensors ])
      (lib.mkIf (builtins.elem "smart" cfg.plugins) [
        "/run/wrappers" # for sudo
        pkgs.smartmontools
        pkgs.nvme-cli
      ])
    ];

    # telegraf user group memberships
    users.users.telegraf.extraGroups = lib.mkMerge [
      (lib.mkIf (builtins.elem "smart" cfg.plugins) [
        "disk"
        "wheel"
      ]) # wheel needed to execute sudo
      (lib.mkIf (builtins.elem "docker" cfg.plugins) [ "docker" ])
    ];

    # postgresql: create telegraf role for monitoring
    services.postgresql.ensureUsers = lib.mkIf (builtins.elem "postgresql" cfg.plugins) [
      {
        name = "telegraf";
        ensureDBOwnership = false;
      }
    ];

    # nginx: enable stub_status endpoint for metrics
    services.nginx.virtualHosts."localhost".locations."/nginx_status" =
      lib.mkIf (builtins.elem "nginx" cfg.plugins)
        {
          extraConfig = ''
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            deny all;
          '';
        };

    # allow disk group to access nvme controller devices (for smart monitoring)
    services.udev.extraRules = lib.mkIf (builtins.elem "smart" cfg.plugins) ''
      KERNEL=="nvme[0-9]*", GROUP="disk", MODE="0660"
    '';

    # sudo rules for telegraf to run smartctl/nvme without password
    security.sudo-rs.extraRules = lib.mkIf (builtins.elem "smart" cfg.plugins) [
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

    services.telegraf.extraConfig = {
      agent = {
        interval = "10s";
        flush_interval = "10s";
      };

      outputs.prometheus_client = [
        {
          listen = ":${toString cfg.listenPort}";
          metric_version = 2;
        }
      ];

      inputs = lib.mkMerge (map (name: inputConfigs.${name}) cfg.plugins);
    };
  };
}
