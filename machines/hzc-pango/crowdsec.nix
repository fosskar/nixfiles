{
  config,
  lib,
  pkgs,
  ...
}:
{
  # create traefik log directory
  systemd.tmpfiles.rules = [
    "d /var/log/traefik 0755 traefik traefik -"
  ];
  services.crowdsec = {
    enable = true;
    openFirewall = false;
    autoUpdateService = true;

    settings = {
      general = {
        api.server.enable = true;
        plugin_config = {
          user = "crowdsec";
          group = "crowdsec";
        };
        prometheus = {
          enabled = true;
          level = "full";
        };
      };

      # lapi credentials (auto-generated on first run)
      lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";
      # capi credentials for community blocklists
      capi.credentialsFile = "/var/lib/crowdsec/state/online_api_credentials.yaml";
    };

    hub = {
      collections = [
        "crowdsecurity/linux-lpe"
        "crowdsecurity/traefik"
        "crowdsecurity/iptables"
        "crowdsecurity/sshd-impossible-travel"
        "crowdsecurity/appsec-virtual-patching"
        "crowdsecurity/appsec-generic-rules"
      ];
    };

    # define log sources
    # note: nixos uses socket-activated sshd, so _SYSTEMD_UNIT=sshd.service won't work
    # for targeted sshd-only logging, use: journalctl_filter = [ "SYSLOG_IDENTIFIER=sshd-session" ];
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
      {
        source = "file";
        filenames = [ "/var/log/traefik/access.log" ];
        labels.type = "traefik";
      }
    ];
  };

  services.crowdsec-firewall-bouncer = {
    enable = true;
    settings.mode = "nftables";
  };

  # auto-register traefik bouncer (same pattern as firewall-bouncer module)
  systemd.services.crowdsec-traefik-bouncer-register =
    let
      apiKeyFile = "/var/lib/crowdsec/traefik-bouncer-api-key.cred";
    in
    {
      description = "Register CrowdSec Traefik bouncer";
      after = [ "crowdsec.service" ];
      wants = [ "crowdsec.service" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        cscli=/run/current-system/sw/bin/cscli
        if $cscli bouncers list --output json | ${lib.getExe pkgs.jq} -e 'any(.[]; .name == "crowdsec-traefik-bouncer")' >/dev/null; then
          # bouncer already registered, verify api key present
          if [ ! -f ${apiKeyFile} ]; then
            echo "bouncer registered but api key missing"
            exit 1
          fi
        else
          # register bouncer and save api key
          rm -f '${apiKeyFile}'
          if ! $cscli bouncers add --output raw crowdsec-traefik-bouncer >${apiKeyFile}; then
            rm -f '${apiKeyFile}'
            exit 1
          fi
          chmod 640 '${apiKeyFile}'
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User = config.services.crowdsec.user;
        Group = config.services.crowdsec.group;
        ReadWritePaths = [ "/var/lib/crowdsec" ];
      };
    };

  # ensure traefik starts after bouncer is registered
  systemd.services.traefik = {
    after = [ "crowdsec-traefik-bouncer-register.service" ];
    wants = [ "crowdsec-traefik-bouncer-register.service" ];
  };

  # ensure bouncer waits for crowdsec API to be ready
  systemd.services.crowdsec-firewall-bouncer = {
    after = [
      "crowdsec.service"
      "local-fs.target"
    ];
    requires = [ "crowdsec.service" ];
    serviceConfig = {
      # retry on failure since crowdsec API may not be ready immediately
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # faster shutdown for crowdsec + memory limit
  systemd.services.crowdsec.serviceConfig = {
    TimeoutStopSec = "10s";
    MemoryMax = "1G";
  };
}
