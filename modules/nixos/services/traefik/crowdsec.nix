{
  flake.modules.nixos.traefik =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      configFile = config.environment.etc."crowdsec/config.yaml".source;
      apiKeyFile = "/var/lib/crowdsec/traefik-bouncer.key";
      pluginModule = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
      # local plugin pinned by hash instead of a runtime download by tag
      pluginSrc = pkgs.fetchFromGitHub {
        owner = "maxlerebourg";
        repo = "crowdsec-bouncer-traefik-plugin";
        tag = "v1.7.1";
        hash = "sha256-hefOKDVsBxn+rCAylPHqbCNfPMbU/vtO4QpiftIPcUU=";
      };
      bouncerName = "crowdsec-traefik-bouncer";
    in
    {
      config = lib.mkIf config.services.crowdsec.enable {
        services.crowdsec = {
          hub.collections = [ "crowdsecurity/traefik" ];
          localConfig.acquisitions = [
            {
              source = "file";
              filenames = [ "/var/log/traefik/access.log" ];
              labels.type = "traefik";
            }
            # WAF: inspects requests forwarded by the traefik plugin;
            # appsec-default chains vpatch-* and generic-* rules
            {
              source = "appsec";
              listen_addr = "127.0.0.1:7422";
              appsec_configs = [ "crowdsecurity/appsec-default" ];
              labels.type = "appsec";
            }
          ];
        };

        services.traefik = {
          staticConfigOptions = {
            experimental.localPlugins.crowdsec-bouncer.moduleName = pluginModule;
          };
          dynamicConfigOptions.http.middlewares.crowdsec.plugin.crowdsec-bouncer = {
            enabled = true;
            crowdsecLapiKeyFile = apiKeyFile;
            crowdsecLapiHost = config.services.crowdsec.settings.general.api.server.listen_uri;
            crowdsecMode = "live";
            crowdsecAppsecEnabled = true;
            crowdsecAppsecHost = "127.0.0.1:7422";
            forwardedHeadersTrustedIPs = [
              "127.0.0.1/32"
              "10.0.0.0/8"
              "172.16.0.0/12"
              "192.168.0.0/16"
            ];
          };
        };

        systemd.tmpfiles.rules = [
          "L+ ${config.services.traefik.dataDir}/plugins-local/src/${pluginModule} - - - - ${pluginSrc}"
        ];
        # the static config names the module, not the version
        systemd.services.traefik.restartTriggers = [ pluginSrc ];

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
              if [ -L /var/lib/crowdsec/traefik-bouncer.key ]; then
                echo "/var/lib/crowdsec/traefik-bouncer.key is a symlink, refusing" >&2
                exit 1
              fi
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
