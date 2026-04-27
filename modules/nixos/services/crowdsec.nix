{
  flake.modules.nixos =
    let
      listenPort = 8085;
      collections = [
        "crowdsecurity/linux-lpe"
        "crowdsecurity/iptables"
        "crowdsecurity/sshd-impossible-travel"
        "crowdsecurity/appsec-virtual-patching"
        "crowdsecurity/appsec-generic-rules"
      ];

      mkConfigFile =
        pkgs: config:
        (pkgs.formats.yaml { }).generate "crowdsec.yaml" config.services.crowdsec.settings.general;
    in
    {
      crowdsec =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          configFile = mkConfigFile pkgs config;
        in
        {
          services.crowdsec = {
            enable = true;
            openFirewall = false;
            autoUpdateService = true;

            settings = {
              general = {
                common.log_level = "warning";
                api.server = {
                  enable = true;
                  listen_uri = "127.0.0.1:${toString listenPort}";
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

            hub.collections = collections;

            localConfig.acquisitions = [
              {
                source = "journalctl";
                journalctl_filter = [ "_TRANSPORT=journal" ];
                labels.type = "syslog";
              }
              {
                source = "journalctl";
                journalctl_filter = [ "_TRANSPORT=syslog" ];
                labels.type = "syslog";
              }
              {
                source = "journalctl";
                journalctl_filter = [ "_TRANSPORT=stdout" ];
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

          preservation.preserveAt."/persist".directories = [
            {
              directory = "/var/lib/crowdsec";
              inherit (config.services.crowdsec) user;
              inherit (config.services.crowdsec) group;
            }
          ];

          systemd.services.crowdsec-firewall-bouncer-register.serviceConfig = {
            StateDirectory = lib.mkForce "crowdsec-firewall-bouncer-register";
            ReadWritePaths = [ "/var/lib/crowdsec" ];
          };
        };

      crowdsecClanWhitelist =
        { config, lib, ... }:
        let
          clanMeshIPs = lib.pipe config.networking.extraHosts [
            (lib.splitString "\n")
            (builtins.filter (line: line != ""))
            (map (line: lib.head (lib.splitString " " line)))
            lib.unique
          ];
        in
        {
          services.crowdsec.localConfig.parsers.s02Enrich = lib.mkIf (clanMeshIPs != [ ]) [
            {
              name = "nixfiles/clan-whitelist";
              description = "whitelist clan mesh network IPs";
              whitelist = {
                reason = "clan mesh network";
                ip = clanMeshIPs;
              };
            }
          ];
        };

      crowdsecTraefik =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          configFile = mkConfigFile pkgs config;
          apiKeyFile = "/var/lib/crowdsec/traefik-bouncer.key";
          bouncerName = "crowdsec-traefik-bouncer";
        in
        {
          services.crowdsec = {
            hub.collections = [ "crowdsecurity/traefik" ];
            localConfig.acquisitions = [
              {
                source = "file";
                filenames = [ "/var/log/traefik/access.log" ];
                labels.type = "traefik";
              }
            ];
          };

          services.traefik = {
            staticConfigOptions = {
              experimental.plugins.crowdsec-bouncer = {
                moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
                version = "v1.4.6";
              };
              entryPoints.websecure.http.middlewares = lib.mkBefore [ "crowdsec@file" ];
            };
            dynamicConfigOptions.http.middlewares.crowdsec.plugin.crowdsec-bouncer = {
              enabled = true;
              crowdsecLapiKeyFile = apiKeyFile;
              crowdsecLapiHost = "127.0.0.1:${toString listenPort}";
              crowdsecMode = "live";
              forwardedHeadersTrustedIPs = [
                "127.0.0.1/32"
                "10.0.0.0/8"
                "172.16.0.0/12"
                "192.168.0.0/16"
              ];
            };
          };

          systemd.services.crowdsec-traefik-bouncer-register = {
            description = "register crowdsec traefik bouncer";
            wantedBy = [ "multi-user.target" ];
            after = [ "crowdsec.service" ];
            wants = [ "crowdsec.service" ];
            script = ''
              cscli=${lib.getExe' config.services.crowdsec.package "cscli"}
              if $cscli -c ${configFile} bouncers list --output json | ${lib.getExe pkgs.jq} -e -- ${lib.escapeShellArg "any(.[]; .name == \"${bouncerName}\")"} >/dev/null; then
                if [ -f ${apiKeyFile} ]; then
                  echo "bouncer already registered, key exists"
                  exit 0
                fi
                echo "bouncer registered but key missing, re-registering"
                $cscli -c ${configFile} bouncers delete ${lib.escapeShellArg bouncerName}
              fi
              rm -f '${apiKeyFile}'
              if ! $cscli -c ${configFile} bouncers add --output raw -- ${lib.escapeShellArg bouncerName} >${apiKeyFile}; then
                rm -f '${apiKeyFile}'
                exit 1
              fi
            '';
            serviceConfig = {
              Type = "oneshot";
              User = config.services.crowdsec.user;
              Group = config.services.crowdsec.group;
              ReadWritePaths = [ "/var/lib/crowdsec" ];
              ExecStartPost = "+${pkgs.writeShellScript "fix-traefik-bouncer-key" ''
                chgrp traefik /var/lib/crowdsec/traefik-bouncer.key
                chmod 0640 /var/lib/crowdsec/traefik-bouncer.key
                systemctl try-restart traefik.service
              ''}";
              DynamicUser = true;
              LockPersonality = true;
              PrivateDevices = true;
              ProcSubset = "pid";
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHome = true;
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              ProtectProc = "invisible";
              RestrictNamespaces = true;
              RestrictRealtime = true;
              SystemCallArchitectures = "native";
              RestrictAddressFamilies = "none";
              CapabilityBoundingSet = [ "" ];
              SystemCallFilter = [
                "@system-service"
                "~@privileged"
                "~@resources"
              ];
              UMask = "0077";
            };
          };
        };

    };
}
