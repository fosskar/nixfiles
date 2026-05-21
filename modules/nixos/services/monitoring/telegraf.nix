{
  flake.modules.nixos.telegraf =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.telegraf;

      zfsEnabled = config.boot.supportedFilesystems.zfs or false;
      ext4Enabled = lib.any (fs: fs.fsType == "ext4") (lib.attrValues config.fileSystems);
      mdraidEnabled = config.boot.swraid.enable or false;
      upsdEnabled = config.power.ups.enable && (config.power.ups.upsd.enable or false);
      postgresqlEnabled = config.services.postgresql.enable;
      redisServers = lib.filterAttrs (_: server: server.enable) config.services.redis.servers;
      redisEnabled = redisServers != { };
      redisSocketServers = lib.filterAttrs (_: server: server.port == 0) redisServers;

      isVM = lib.any (m: m == "xen-blkfront" || m == "virtio_console") config.boot.initrd.kernelModules;

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
      config = lib.mkIf cfg.enable {
        services.telegraf = {
          extraConfig = {
            agent = {
              interval = "30s";
              flush_interval = "30s";
            };

            inputs = {
              cpu = [ { } ];
              mem = [ { } ];
              swap = [ { } ];
              disk = [
                {
                  tagdrop = {
                    fstype = [
                      "tmpfs"
                      "ramfs"
                      "devtmpfs"
                      "devfs"
                      "iso9660"
                      "overlay"
                      "aufs"
                      "squashfs"
                      "efivarfs"
                    ];
                    device = [
                      "rpc_pipefs"
                      "lxcfs"
                      "nsfs"
                      "borgfs"
                    ];
                  };
                }
              ];
              diskio = [ { } ];
              net = [ { } ];
              system = [ { } ];
              processes = [ { } ];
              kernel_vmstat = [ { } ];
              internal = [ { } ];

              systemd_units = { };

              mdstat = lib.mkIf mdraidEnabled { };

              file = lib.mkIf ext4Enabled [
                {
                  name_override = "ext4_errors";
                  files = [ "/sys/fs/ext4/*/errors_count" ];
                  data_format = "value";
                }
              ];

              sensors = lib.mkIf (!isVM) [ { } ];

              smart = lib.mkIf (!isVM) [
                {
                  path_smartctl = "/run/wrappers/bin/smartctl-telegraf";
                  path_nvme = "/run/wrappers/bin/nvme-telegraf";
                  attributes = true;
                  nocheck = "standby"; # skip disks in standby, do not wake sleeping disks
                }
              ];

              zfs = lib.mkIf zfsEnabled [
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

              upsd = lib.mkIf upsdEnabled [
                {
                  server = "127.0.0.1";
                  port = 3493;
                }
              ];

              postgresql = lib.mkIf postgresqlEnabled [
                {
                  address = "host=/run/postgresql user=telegraf dbname=postgres sslmode=disable";
                }
              ];

              redis = lib.mkIf redisEnabled [
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

              exec = [
                {
                  commands = [ ipv6DadCheck ] ++ lib.optional zfsEnabled zpoolHealth;
                  data_format = "influx";
                }
              ];
            };

            outputs.prometheus_client = lib.mkDefault [
              {
                listen = ":9273";
                metric_version = 2;
              }
            ];
          };
        };

        systemd.services.telegraf.path = lib.optional (!isVM) pkgs.lm_sensors;

        services.postgresql.ensureUsers = lib.mkIf postgresqlEnabled [
          {
            name = "telegraf";
            ensureDBOwnership = false;
          }
        ];

        users.users.telegraf.extraGroups = lib.mkIf (redisSocketServers != { }) (
          lib.unique (map (server: server.group) (lib.attrValues redisSocketServers))
        );

        security.wrappers = lib.mkIf (!isVM) {
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
