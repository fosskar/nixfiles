{ ... }:
{
  # create traefik log directory
  systemd.tmpfiles.rules = [
    "d /var/log/traefik 0755 traefik traefik -"
  ];
  services.crowdsec = {
    enable = true;

    autoUpdateService = true;

    settings = {
      general.api.server = {
        enable = true;
      };

      # lapi credentials (auto-generated on first run)
      lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";
      # capi credentials for community blocklists
      capi.credentialsFile = "/var/lib/crowdsec/state/online_api_credentials.yaml";
    };

    hub = {
      collections = [
        "crowdsecurity/linux" # sshd, syslog
        "crowdsecurity/traefik" # traefik access logs
        "crowdsecurity/iptables" # port scans
        "crowdsecurity/http-cve" # known CVE exploits
      ];
      postOverflows = [
        "crowdsecurity/cdn-whitelist" # don't ban cloudflare/fastly IPs
      ];
    };

    # define log sources
    localConfig.acquisitions = [
      {
        source = "journalctl";
        journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
        labels.type = "syslog";
      }
      {
        filenames = [ "/var/log/traefik/access.log" ];
        labels.type = "traefik";
      }
    ];
  };

  services.crowdsec-firewall-bouncer = {
    enable = true;
    settings.mode = "nftables";
  };
}
