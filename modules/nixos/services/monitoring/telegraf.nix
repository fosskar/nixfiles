{
  flake.modules.nixos.telegraf =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      cfg = config.services.telegraf;

      enabledNixosSystemdServices = builtins.map (name: "${name}.service") (
        lib.attrNames (
          lib.filterAttrs (_: value: value) (
            lib.mapAttrs (
              name: value:
              builtins.hasAttr "enable" options.services."${name}"
              && builtins.hasAttr "default" options.services."${name}".enable
              && options.services."${name}".enable.default != value.enable
              && value.enable
            ) config.services
          )
        )
      );

      systemdUnitPattern =
        if enabledNixosSystemdServices == [ ] then
          "__no_nixos_services__.service"
        else
          lib.concatStringsSep " " enabledNixosSystemdServices;

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

        systemd = {
          systemd_units = [
            {
              pattern = systemdUnitPattern;
              unittype = "service";
            }
          ];
        };

        sensors = {
          sensors = [ { } ];
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

        postgresql = {
          postgresql = [
            {
              address = "host=/run/postgresql user=telegraf dbname=postgres sslmode=disable";
            }
          ];
        };

        smart = {
          smart = [
            {
              path_smartctl = "/run/wrappers/bin/smartctl-telegraf";
              path_nvme = "/run/wrappers/bin/nvme-telegraf";
              attributes = true;
              nocheck = "standby"; # skip disks in standby, do not wake sleeping disks
            }
          ];
        };
      };

      zfsEnabled = config.boot.supportedFilesystems.zfs or false;
      upsdEnabled = config.power.ups.enable && (config.power.ups.upsd.enable or false);
      postgresqlEnabled = config.services.postgresql.enable;
      redisServers = lib.filterAttrs (_: server: server.enable) config.services.redis.servers;
      redisEnabled = redisServers != { };

      ipv6DadCheck = pkgs.writeShellScript "ipv6-dad-check" ''
        ${pkgs.iproute2}/bin/ip --json addr | \
          ${pkgs.jq}/bin/jq -r 'map(.addr_info) | flatten(1) | map(select(.dadfailed == true)) | map(.local) | @text "ipv6_dad_failures count=\(length)i"'
      '';

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
      options.services.telegraf.smart.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "enable telegraf smart input and privileged smartctl/nvme wrappers";
      };

      options.services.telegraf.sensors.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          enable telegraf lm-sensors input. disable on hosts without
          /sys/class/hwmon (e.g. KVM/cloud VMs) to avoid recurring
          `inputs.sensors` plugin errors.
        '';
      };

      config = lib.mkIf cfg.enable {
        services.telegraf = {
          package = pkgs.telegraf;
          extraConfig = {
            agent = {
              interval = "30s";
              flush_interval = "30s";
            };

            inputs = lib.mkMerge [
              inputConfigs.system
              inputConfigs.systemd
              (lib.mkIf config.services.telegraf.sensors.enable inputConfigs.sensors)
              {
                exec = [
                  {
                    commands = [ ipv6DadCheck ];
                    data_format = "influx";
                  }
                ]
                ++ lib.optional zfsEnabled {
                  commands = [ zpoolHealth ];
                  data_format = "influx";
                };
              }
              (lib.mkIf zfsEnabled inputConfigs.zfs)
              (lib.mkIf upsdEnabled inputConfigs.upsd)
              (lib.mkIf postgresqlEnabled inputConfigs.postgresql)
              (lib.mkIf redisEnabled {
                redis = [
                  {
                    servers = lib.mapAttrsToList (
                      _: server:
                      if server.port != 0 then
                        "tcp://${server.bind}:${toString server.port}"
                      else
                        "unix://${server.unixSocket}"
                    ) redisServers;
                  }
                ];
              })
              (lib.mkIf cfg.smart.enable inputConfigs.smart)
            ];

            outputs.prometheus_client = lib.mkDefault [
              {
                listen = ":9273";
                metric_version = 2;
              }
            ];
          };
        };

        systemd.services.telegraf.path = [ pkgs.lm_sensors ];

        services.postgresql.ensureUsers = lib.mkIf postgresqlEnabled [
          {
            name = "telegraf";
            ensureDBOwnership = false;
          }
        ];

        users.users.telegraf.extraGroups = lib.mkIf redisEnabled (
          lib.unique (map (server: server.group) (lib.attrValues redisServers))
        );

        services.udev.extraRules = lib.mkIf cfg.smart.enable ''
          KERNEL=="nvme[0-9]*", GROUP="disk", MODE="0660"
        '';

        security.wrappers = lib.mkIf cfg.smart.enable {
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
    };
}
