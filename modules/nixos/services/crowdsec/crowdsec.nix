{
  flake.modules.nixos.crowdsec =
    {
      config,
      lib,
      options,
      ...
    }:
    {
      config = {
        services.crowdsec = {
          enable = true;
          autoUpdateService = true;

          settings = {
            config = {
              common.log_level = "warning";
              # data_dir defaulted to state/ before the nixpkgs module rewrite; keeps the db and hub
              config_paths.data_dir = "/var/lib/crowdsec/state";
              db_config.use_wal = true;
              api.server = {
                enable = true;
                listen_uri = "127.0.0.1:8085";
                online_client.credentials_path = "/var/lib/crowdsec/state/online_api_credentials.yaml";
              };
              api.client.credentials_path = "/var/lib/crowdsec/state/local_api_credentials.yaml";
              plugin_config = {
                user = "crowdsec";
                group = "crowdsec";
              };
              prometheus = {
                enabled = true;
                level = "full";
                listen_addr = "127.0.0.1";
                listen_port = 6061;
              };
            };

            acquisitions = [
              {
                source = "journalctl";
                # dev-log is world-writable and SYSLOG_IDENTIFIER is sender-chosen; only root
                # (sshd) entries may feed the ban scenarios
                journalctl_filter = [
                  "_TRANSPORT=syslog"
                  "_UID=0"
                ];
                labels.type = "syslog";
              }
              {
                source = "journalctl";
                journalctl_filter = [ "_TRANSPORT=kernel" ];
                labels.type = "syslog";
              }
            ];
          };

          hub.collections = [
            "crowdsecurity/linux-lpe"
            "crowdsecurity/iptables"
            "crowdsecurity/sshd-impossible-travel"
            "crowdsecurity/appsec-virtual-patching"
            "crowdsecurity/appsec-generic-rules"
          ];
        };

        services.crowdsec-firewall-bouncer = {
          enable = true;
          settings.mode = "nftables";
          registerBouncer.enable = true;
        };

        services.telegraf.extraConfig.inputs.prometheus = lib.mkIf config.services.telegraf.enable [
          {
            urls = [ "http://127.0.0.1:6061/metrics" ];
          }
        ];

        services.grafana.provision.dashboards.settings.providers = [
          {
            name = "crowdsec";
            folder = "Security";
            options.path = ./crowdsec.dashboard.json;
          }
        ];

        systemd.services = {
          crowdsec-update-hub.serviceConfig.ExecStartPost = lib.mkForce "+systemctl restart crowdsec.service";

          # upstream race crashes crowdsec (crowdsecurity/crowdsec#4459); without
          # a restart the traefik bouncer fails closed and 403s all ingress
          crowdsec.unitConfig.StartLimitIntervalSec = 0;

          crowdsec-firewall-bouncer-register.serviceConfig = {
            StateDirectory = lib.mkForce "crowdsec-firewall-bouncer-register";
            ReadWritePaths = [ "/var/lib/crowdsec" ];
          };
        };

        # nixpkgs module installs settings yamls via tmpfiles;
        # nothing restarts crowdsec when they change, so rule edits would
        # silently never load until the next manual restart/reboot
        systemd.services.crowdsec.restartTriggers = [
          (builtins.toJSON {
            inherit (config.services.crowdsec.settings)
              acquisitions
              parsers
              postOverflows
              scenarios
              profiles
              ;
          })
        ];
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          {
            directory = "/var/lib/crowdsec";
            inherit (config.services.crowdsec) user;
            inherit (config.services.crowdsec) group;
          }
        ];
      };
    };
}
