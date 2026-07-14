{
  flake.modules.nixos.crowdsec =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      configFile =
        (pkgs.formats.yaml { }).generate "crowdsec.yaml"
          config.services.crowdsec.settings.general;
    in
    {
      config = {
        services.crowdsec = {
          enable = true;
          openFirewall = false;
          autoUpdateService = true;

          settings = {
            general = {
              common.log_level = "warning";
              api.server = {
                enable = true;
                listen_uri = "127.0.0.1:8085";
              };
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
            lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";
            capi.credentialsFile = "/var/lib/crowdsec/state/online_api_credentials.yaml";
          };

          hub.collections = [
            "crowdsecurity/linux-lpe"
            "crowdsecurity/iptables"
            "crowdsecurity/sshd-impossible-travel"
            "crowdsecurity/appsec-virtual-patching"
            "crowdsecurity/appsec-generic-rules"
          ];

          localConfig.acquisitions = [
            {
              source = "journalctl";
              journalctl_filter = [ "_TRANSPORT=syslog" ];
              labels.type = "syslog";
            }
            {
              source = "journalctl";
              journalctl_filter = [ "_TRANSPORT=kernel" ];
              labels.type = "syslog";
            }
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

        environment.etc."crowdsec/config.yaml".source = configFile;

        systemd.services = {
          crowdsec-update-hub.serviceConfig.ExecStartPost = lib.mkForce "+systemctl restart crowdsec.service";

          crowdsec-firewall-bouncer-register.serviceConfig = {
            StateDirectory = lib.mkForce "crowdsec-firewall-bouncer-register";
            ReadWritePaths = [ "/var/lib/crowdsec" ];
          };
        };

        # nixpkgs module installs localConfig yamls via tmpfiles symlinks;
        # nothing restarts crowdsec when they change, so rule edits would
        # silently never load until the next manual restart/reboot
        systemd.services.crowdsec.restartTriggers = [
          (builtins.toJSON {
            inherit (config.services.crowdsec.localConfig)
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
