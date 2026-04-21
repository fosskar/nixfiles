# crowdsec security engine with firewall bouncer
#
# workarounds for nixos module issues on ephemeral root systems:
# - symlink /etc/crowdsec/config.yaml (bouncer-register calls raw cscli)
# - override firewall-bouncer-register StateDirectory (cross-device link with persistence)
# remove workarounds when nixpkgs#446307 lands
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

  # extract IPs from networking.extraHosts (populated by clan yggdrasil + wireguard)
  clanMeshIPs = lib.pipe config.networking.extraHosts [
    (lib.splitString "\n")
    (builtins.filter (line: line != ""))
    (map (line: lib.head (lib.splitString " " line)))
    lib.unique
  ];

  allWhitelistIPs = cfg.whitelistIPs ++ lib.optionals cfg.whitelistClanMesh clanMeshIPs;
in
{
  # --- options ---

  options.nixfiles.crowdsec = {
    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 8085;
      description = "crowdsec LAPI port (default avoids conflict with nginx:8080 and prometheus:6060)";
    };

    whitelistIPs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "IPs to whitelist from crowdsec bans (e.g. clan mesh IPs)";
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

    netbirdProxy.enable = lib.mkEnableOption "register a bouncer for the netbird-proxy built-in crowdsec integration (netbird >= 0.69.0)";
  };

  # --- service ---

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
            # netbird-proxy hardcodes pprof on :6060, avoid conflict
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

        # whitelist clan mesh IPs so they never get banned
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

    # export crowdsec metrics via telegraf scrape endpoint
    services.telegraf.extraConfig.inputs.prometheus = lib.mkIf config.services.telegraf.enable [
      {
        urls = [ "http://127.0.0.1:6061/metrics" ];
      }
    ];

    # workaround: bouncer-register calls raw cscli which expects /etc/crowdsec/config.yaml
    environment.etc."crowdsec/config.yaml".source = configFile;

    # traefik bouncer plugin + middleware (when enabled)
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

    # --- persistence ---

    nixfiles.persistence.directories = [
      {
        directory = "/var/lib/crowdsec";
        inherit (config.services.crowdsec) user;
        inherit (config.services.crowdsec) group;
      }
    ];

    # --- systemd ---

    # workaround: nixpkgs sets StateDirectory = "... crowdsec" which conflicts
    # with persisted /var/lib/crowdsec bind mount (cross-device link)
    systemd.services.crowdsec-firewall-bouncer-register.serviceConfig = {
      StateDirectory = lib.mkForce "crowdsec-firewall-bouncer-register";
      ReadWritePaths = [ "/var/lib/crowdsec" ];
    };

    # netbird-proxy bouncer registration (oneshot)
    # netbird-proxy reads NB_PROXY_CROWDSEC_API_KEY from this file at startup;
    # ordering ensures the key exists before netbird-proxy starts
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
          # must be crowdsec user: cscli needs write access to data_dir
          # (/var/lib/crowdsec/state/trace), which is 0750 crowdsec:crowdsec
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

    # traefik bouncer registration (oneshot)
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
}
