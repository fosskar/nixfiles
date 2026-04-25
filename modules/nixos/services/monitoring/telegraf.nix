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
          kernel_vmstat = [ { } ];
          internal = [ { } ];
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
              path_smartctl = "/run/wrappers/bin/smartctl-telegraf";
              path_nvme = "/run/wrappers/bin/nvme-telegraf";
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
        x509_cert = domains: {
          x509_cert = [
            {
              sources = [ "https://${domains.local}:443" ];
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
                interval = "30s";
                flush_interval = "30s";
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
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          ipv6DadCheck = pkgs.writeShellScript "ipv6-dad-check" ''
            ${pkgs.iproute2}/bin/ip --json addr | \
              ${pkgs.jq}/bin/jq -r 'map(.addr_info) | flatten(1) | map(select(.dadfailed == true)) | map(.local) | @text "ipv6_dad_failures count=\(length)i"'
          '';
        in
        {
          services.telegraf.extraConfig.inputs = lib.mkIf config.services.telegraf.enable (
            inputConfigs.system
            // {
              exec = [
                {
                  commands = [ ipv6DadCheck ];
                  data_format = "influx";
                }
              ];
            }
          );
        };

      telegrafSystemd =
        { config, lib, ... }:
        {
          services.telegraf.extraConfig.inputs = lib.mkIf config.services.telegraf.enable inputConfigs.systemd;
        };

      telegrafZfs =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          zpoolHealth = pkgs.writeScript "zpool-health" ''
            #!${pkgs.gawk}/bin/awk -f
            BEGIN {
              while ("${config.boot.zfs.package}/bin/zpool status" | getline) {
                if ($1 ~ /pool:/) { printf "zpool_status,name=%s ", $2 }
                if ($1 ~ /state:/) { printf "state=\"%s\",", $2 }
                if ($1 ~ /errors:/) {
                  if (index($2, "No")) printf "errors=0i\n"; else printf "errors=%di\n", $2
                }
              }
            }
          '';
        in
        {
          services.telegraf.extraConfig.inputs = lib.mkIf config.services.telegraf.enable (
            inputConfigs.zfs
            // {
              exec = lib.optional (config.boot.supportedFilesystems.zfs or false) {
                commands = [ zpoolHealth ];
                data_format = "influx";
              };
            }
          );
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

          security.wrappers = {
            smartctl-telegraf = {
              owner = "telegraf";
              group = "telegraf";
              capabilities = "cap_sys_admin,cap_dac_override,cap_sys_rawio+ep";
              source = "${pkgs.smartmontools}/bin/smartctl";
            };
            nvme-telegraf = {
              owner = "telegraf";
              group = "telegraf";
              capabilities = "cap_sys_admin,cap_dac_override,cap_sys_rawio+ep";
              source = "${pkgs.nvme-cli}/bin/nvme";
            };
          };
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
        {
          config,
          domains,
          lib,
          ...
        }:
        {
          services.telegraf.extraConfig.inputs = lib.mkIf config.services.telegraf.enable (
            inputConfigs.x509_cert domains
          );
        };
    };
}
