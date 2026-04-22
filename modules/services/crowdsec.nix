# crowdsec security engine with firewall bouncer
{
  flake.modules.nixos.crowdsec =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.nixfiles.crowdsec;
      format = pkgs.formats.yaml { };
      configFile = format.generate "crowdsec.yaml" config.services.crowdsec.settings.general;

      clanMeshIPs = lib.pipe config.networking.extraHosts [
        (lib.splitString "\n")
        (builtins.filter (line: line != ""))
        (map (line: lib.head (lib.splitString " " line)))
        lib.unique
      ];

      allWhitelistIPs = cfg.whitelistIPs ++ lib.optionals cfg.whitelistClanMesh clanMeshIPs;
    in
    {
      options.nixfiles.crowdsec = {
        listenPort = lib.mkOption {
          type = lib.types.port;
          default = 8085;
          description = "crowdsec LAPI port";
        };

        whitelistIPs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "IPs to whitelist from crowdsec bans";
        };

        whitelistClanMesh = lib.mkEnableOption "auto-whitelist all clan mesh IPs from networking.extraHosts";

        collections = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "crowdsecurity/linux-lpe"
            "crowdsecurity/iptables"
            "crowdsecurity/sshd-impossible-travel"
            "crowdsecurity/appsec-virtual-patching"
            "crowdsecurity/appsec-generic-rules"
          ];
          description = "crowdsec hub collections to install";
        };

        acquisitions = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = [ ];
          description = "additional log acquisition sources";
        };

        traefik.enable = lib.mkEnableOption "traefik bouncer plugin + middleware + log acquisition";

        netbirdProxy.enable = lib.mkEnableOption "register a bouncer for the netbird-proxy built-in crowdsec integration";
      };

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
                listen_uri = "127.0.0.1:${toString cfg.listenPort}";
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

          hub.collections = cfg.collections ++ lib.optionals cfg.traefik.enable [ "crowdsecurity/traefik" ];

          localConfig = {
            acquisitions = [
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
            ]
            ++ lib.optionals cfg.traefik.enable [
              {
                source = "file";
                filenames = [ "/var/log/traefik/access.log" ];
                labels.type = "traefik";
              }
            ]
            ++ [
              {
                source = "journalctl";
                journalctl_filter = [ "_SYSTEMD_UNIT=netbird-proxy.service" ];
                labels.type = "netbird-proxy";
              }
            ]
            ++ cfg.acquisitions;

            parsers.s02Enrich = lib.mkIf (allWhitelistIPs != [ ]) [
              {
                name = "nixfiles/clan-whitelist";
                description = "whitelist clan mesh network IPs";
                whitelist = {
                  reason = "clan mesh network";
                  ip = allWhitelistIPs;
                };
              }
            ];
          };
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

        services.traefik = lib.mkIf cfg.traefik.enable {
          staticConfigOptions = {
            experimental.plugins.crowdsec-bouncer = {
              moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
              version = "v1.4.6";
            };
            entryPoints.websecure.http.middlewares = lib.mkBefore [ "crowdsec@file" ];
          };
          dynamicConfigOptions.http.middlewares.crowdsec.plugin.crowdsec-bouncer = {
            enabled = true;
            crowdsecLapiKeyFile = "/var/lib/crowdsec/traefik-bouncer.key";
            crowdsecLapiHost = "127.0.0.1:${toString cfg.listenPort}";
            crowdsecMode = "live";
            forwardedHeadersTrustedIPs = [
              "127.0.0.1/32"
              "10.0.0.0/8"
              "172.16.0.0/12"
              "192.168.0.0/16"
            ];
          };
        };

        nixfiles.preservation.directories = [
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

        systemd.services.crowdsec-netbird-proxy-bouncer-register = lib.mkIf cfg.netbirdProxy.enable (
          let
            apiKeyFile = "/var/lib/crowdsec/netbird-proxy-bouncer.key";
            bouncerName = "netbird-proxy";
          in
          {
            description = "register crowdsec netbird-proxy bouncer";
            wantedBy = [ "multi-user.target" ];
            before = [ "netbird-proxy.service" ];
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
              RemainAfterExit = true;
              User = config.services.crowdsec.user;
              Group = config.services.crowdsec.group;
              ReadWritePaths = [ "/var/lib/crowdsec" ];
              ExecStartPost = "+${pkgs.writeShellScript "fix-netbird-proxy-bouncer-key" ''
                chgrp netbird /var/lib/crowdsec/netbird-proxy-bouncer.key
                chmod 0640 /var/lib/crowdsec/netbird-proxy-bouncer.key
              ''}";
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
          }
        );

        systemd.services.crowdsec-traefik-bouncer-register = lib.mkIf cfg.traefik.enable (
          let
            apiKeyFile = "/var/lib/crowdsec/traefik-bouncer.key";
            bouncerName = "crowdsec-traefik-bouncer";
          in
          {
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
          }
        );
      };
    };
}
