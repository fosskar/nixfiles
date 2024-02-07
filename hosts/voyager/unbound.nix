{
  pkgs,
  lib,
  ...
}: {
  services.unbound = {
    enable = true;
    package = pkgs.unbound-full;
    localControlSocketPath = "/run/unbound/unbound.ctl";
    resolveLocalQueries = true;
    settings = {
      server = {
        access-control = [
          "127.0.0.0/8 allow"
          "192.168.0.0/16 allow"
          "::1/128 allow"
        ];
        aggressive-nsec = true;
        cache-max-ttl = 86400;
        cache-min-ttl = 300;
        delay-close = 10000;
        rrset-cache-size = "256m";
        msg-cache-size = "128m";
        do-ip4 = true;
        do-ip6 = true;
        do-tcp = true;
        do-udp = true;
        edns-buffer-size = "1472";
        statistics-interval = 0;
        extended-statistics = "yes";
        statistics-cumulative = "yes";
        harden-algo-downgrade = false;
        harden-below-nxdomain = true;
        harden-dnssec-stripped = true;
        harden-glue = true;
        harden-large-queries = true;
        harden-short-bufsize = true;
        qname-minimisation = true;
        use-caps-for-id = "yes";
        use-syslog = "yes";
        log-replies = true;
        log-queries = true;
        log-tag-queryreply = true;
        log-local-actions = true;
        log-servfail = true;
        verbosity = 0;
        logfile = "/var/lib/unbound/unbound.log";
        so-reuseport = true;
        interface = ["::1" "127.0.0.1" "192.168.178.91"];
        prefetch = "yes";
        prefetch-key = true;
        private-address = [
          "10.0.0.0/8"
          "169.254.0.0/16"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "fd00::/8"
          "fe80::/10"
        ];
        #private-domain = ["oscar"];
        #domain-insecure = ["oscar"];
        local-zone = [
          "'space.' static"
        ];
        local-data = [
          "'grafana.space IN A 192.168.178.91'"
          "'prometheus.space IN A 192.168.178.91'"
          "'loki.space IN A 192.168.178.91'"
          "'promtail.space IN A 192.168.178.91'"
          "'vaultwarden.space IN A 192.168.178.91'"
          "'kanidm.space IN A 192.168.178.91'"
          "'dashy.space IN A 192.168.178.91'"
          "'cockpit.space IN A 192.168.178.91'"
          "'pihole.space IN A 192.168.178.91'"
        ];
      };
    };
  };
  # no need for a systemd-resolved stub
  services.resolved.enable = false;

  # Since we use this for local dns resolving, we don't want to stop/start but
  # just restart, so we quickly get it back.
  systemd.services.unbound.stopIfChanged = false;
}
