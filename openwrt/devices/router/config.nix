# GL.iNet GL-MT6000 (flint 2) — main router
# TODO: run `nix run .#openwrt-fetch-router` to dump current config, then adjust below
{
  host = "192.168.10.1";

  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA openpgp:0xDA6712BE"
  ];

  packages = [
    "adguardhome"

    "dawn"
    "luci-app-dawn"

    "wpad-wolfssl"

    "irqbalance"

    "telegraf-full"
    "prometheus-node-exporter-lua"

    "unbound-daemon"
    "unbound-control"
    "unbound-control-setup"
    "luci-app-unbound"

    "sqm-scripts"
    "luci-app-sqm"
  ];

  removePackages = [
    "wpad-basic-wolfssl" # gets replaced by full wpad-wolfssl package, because some options missing that needed by DAWN
  ];

  files = {
    "/etc/unbound/unbound_srv.conf" = ./files/unbound_srv.conf;
    "/etc/unbound/unbound_ext.conf" = ./files/unbound_ext.conf;
  };

  uci = {
    secrets.sops.files = [ ../secrets.yaml ];

    settings = {
      attendedsysupgrade.client = {
        _type = "client";
        advanced_mode = "1";
        login_check_for_upgrades = "1";
      };

      # install: sh <(wget -qO- https://github.com/vernette/beszel-agent-openwrt/raw/master/install.sh)
      beszel-agent.agent = {
        _type = "agent";
        enabled = "1";
        port = "45876";
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHN601z/tNqh+R7x9JaCDayBioT2aQs1tEGv0tOSF/wu";
        hub_url = "https://beszel.nx3.eu";
        token = "@beszel_token_router@";
      };

      system.system = [
        {
          _type = "system";
          hostname = "openwrt";
        }
      ];

      network = {
        globals = {
          _type = "globals";
          packet_steering = "2";
        };
        device = [
          {
            _type = "device";
            name = "br-lan";
            type = "bridge";
            ports = [
              "lan1"
              "lan2"
              "lan3"
              "lan4"
              "lan5"
            ];
          }
          {
            _type = "device";
            name = "br-iot";
            type = "bridge";
          }
          {
            _type = "device";
            name = "br-guest";
            type = "bridge";
          }
        ];
        lan = {
          _type = "interface";
          device = "br-lan";
          proto = "static";
          ipaddr = "192.168.10.1";
          netmask = "255.255.255.0";
          ip6assign = "60";
        };
        wan = {
          _type = "interface";
          device = "eth1";
          proto = "pppoe";
          username = "@pppoe_username@";
          password = "@pppoe_password@";
          ipv6 = "auto";
          peerdns = "0";
          dns = "127.0.0.1";
        };
        wan6 = {
          _type = "interface";
          device = "eth1";
          proto = "dhcpv6";
          peerdns = "0";
          dns = "::1";
        };
        iot = {
          _type = "interface";
          device = "br-iot";
          proto = "static";
          ipaddr = "192.168.50.1/24";
        };
      };

      wireless = {
        radio0 = {
          _type = "wifi-device";
          type = "mac80211";
          path = "platform/soc/18000000.wifi";
          band = "2g";
          channel = "11";
          htmode = "HE20";
          country = "DE";
        };
        # main wifi — 2.4GHz
        main_2g = {
          _type = "wifi-iface";
          device = "radio0";
          network = "lan";
          mode = "ap";
          ssid = "@wifi_ssid_main@";
          key = "@wifi_password_main@";
          encryption = "sae-mixed";
          ieee80211r = "1";
          ieee80211k = "1";
          bss_transition = "1";
        };
        # IoT wifi — hidden, 2.4GHz only, separate network
        iot = {
          _type = "wifi-iface";
          device = "radio0";
          network = "iot";
          mode = "ap";
          ssid = "@wifi_ssid_iot@";
          encryption = "psk2";
          key = "@wifi_password_iot@";
          hidden = "1";
        };

        radio1 = {
          _type = "wifi-device";
          type = "mac80211";
          path = "platform/soc/18000000.wifi+1";
          band = "5g";
          channel = "36";
          htmode = "HE80";
          country = "DE";
        };
        # main wifi — 5GHz
        main_5g = {
          _type = "wifi-iface";
          device = "radio1";
          network = "lan";
          mode = "ap";
          ssid = "@wifi_ssid_main@";
          key = "@wifi_password_main@";
          encryption = "sae-mixed";
          ieee80211r = "1";
          ieee80211k = "1";
          bss_transition = "1";
        };
      };

      dhcp = {
        dnsmasq = [
          {
            _type = "dnsmasq";
            domainneeded = "1";
            localise_queries = "1";
            rebind_protection = "1";
            rebind_localhost = "1";
            local = "/lan/";
            domain = "lan";
            expandhosts = "1";
            cachesize = "0"; # adguard home handles DNS caching
            readethers = "1";
            leasefile = "/tmp/dhcp.leases";
            resolvfile = "/tmp/resolv.conf.d/resolv.conf.auto";
            localservice = "1";
            ednspacket_max = "1232";
            port = "54"; # adguard uses 53
            noresolv = "1";
          }
        ];
        lan = {
          _type = "dhcp";
          interface = "lan";
          dhcpv4 = "server";
          dhcpv6 = "server";
          ra = "server";
          ra_flags = [
            "managed-config"
            "other-config"
          ];
          dhcp_option = [
            "3,192.168.10.1"
            "6,192.168.10.1"
            "15,lan"
          ];
          dns = "fd8a:2e59:7bfd::1";
        };
        iot = {
          _type = "dhcp";
          interface = "iot";
          start = "100";
          limit = "150";
          leasetime = "12h";
        };
      };

      # clients → AdGuard (port 53, filtering) → unbound (port 5335, recursive resolution) → root DNS servers (-> dnsmaq (port 54, caching, DHCP integration, local DNS))
      unbound = {
        ub_main = {
          _type = "unbound";
          enabled = "1";
          dhcp_link = "dnsmasq";
          extended_stats = "1";
          listen_port = "5335";
          num_threads = "4";
          recursion = "aggressive";
          resource = "large";
          ttl_min = "1200";
          unbound_control = "2";
          validator = "1";
          query_minimize = "1";
          iface_trig = "wan";
          iface_lan = "lan";
        };
        auth_icann = {
          _type = "zone";
          enabled = "1";
        };
      };

      # --- sqm (traffic shaping) ---
      # note: hardware offloading (flow_offloading_hw) is incompatible with sqm,
      # so we only use software offloading (flow_offloading) in the firewall defaults.
      # see: https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm
      sqm.eth1 = {
        _type = "queue";
        enabled = "1";
        interface = "eth1";
        download = "260000";
        upload = "45000";
        qdisc = "cake";
        script = "piece_of_cake.qos";
        linklayer = "ethernet";
        overhead = "44";
        linklayer_advanced = "1";
        tcMPU = "84";
        qdisc_advanced = "1";
        squash_dscp = "0";
        squash_ingress = "0";
        iqdisc_opts = "nat dual-dsthost ingress";
        eqdisc_opts = "nat dual-srchost ack-filter";
      };

      firewall = {
        defaults = [
          {
            _type = "defaults";
            flow_offloading = "1"; # software offloading to work with sqm
          }
        ];
        zone = [
          {
            _type = "zone";
            name = "wan";
            network = [
              "wan"
              "wan6"
            ];
            input = "REJECT";
            output = "ACCEPT";
            forward = "DROP";
            masq = "1";
            mtu_fix = "1";
          }
          {
            _type = "zone";
            name = "lan";
            network = [ "lan" ];
            input = "ACCEPT";
            output = "ACCEPT";
            forward = "ACCEPT";
          }
          {
            _type = "zone";
            name = "iot";
            network = [ "iot" ];
            input = "ACCEPT";
            output = "ACCEPT";
            forward = "ACCEPT";
            masq = "1";
          }
        ];
        forwarding = [
          {
            _type = "forwarding";
            src = "lan";
            dest = "wan";
          }
          {
            _type = "forwarding";
            src = "iot";
            dest = "wan";
          }
          {
            _type = "forwarding";
            src = "lan";
            dest = "iot";
          }
        ];
        redirect = [
          # this intercepts every connection and forces it to use the router for DNS, so that adguard home can filter DNS requests and block ads, trackers, etc. even if the client has a custom DNS server configured
          {
            _type = "redirect";
            target = "DNAT";
            name = "Force DNS Interception";
            proto = "udp";
            src = "lan";
            src_dport = "53";
            dest_ip = "192.168.10.1";
            dest_port = "53";
          }
          {
            _type = "redirect";
            target = "DNAT";
            name = "Force DNS Interception - IoT";
            proto = "udp";
            src = "iot";
            src_dport = "53";
            dest_ip = "192.168.10.1";
            dest_port = "53";
          }
        ];
        #rule = [
        #  {
        #    _type = "rule";
        #    name = "Allow-DHCP-Renew";
        #    src = "wan";
        #    proto = "udp";
        #    dest_port = "68";
        #    target = "ACCEPT";
        #    family = "ipv4";
        #  }
        #  {
        #    _type = "rule";
        #    name = "Allow-Ping";
        #    src = "wan";
        #    proto = "icmp";
        #    icmp_type = "echo-request";
        #    family = "ipv4";
        #    target = "ACCEPT";
        #  }
        #  {
        #    _type = "rule";
        #    name = "Allow-IGMP";
        #    src = "wan";
        #    proto = "igmp";
        #    family = "ipv4";
        #    target = "ACCEPT";
        #  }
        #  {
        #    _type = "rule";
        #    name = "Allow-DHCPv6";
        #    src = "wan";
        #    proto = "udp";
        #    dest_port = "546";
        #    family = "ipv6";
        #    target = "ACCEPT";
        #  }
        #  {
        #    _type = "rule";
        #    name = "Allow-MLD";
        #    src = "wan";
        #    proto = "icmp";
        #    src_ip = "fe80::/10";
        #    icmp_type = [
        #      "130/0"
        #      "131/0"
        #      "132/0"
        #      "143/0"
        #    ];
        #    family = "ipv6";
        #    target = "ACCEPT";
        #  }
        #  {
        #    _type = "rule";
        #    name = "Allow-ICMPv6-Input";
        #    src = "wan";
        #    proto = "icmp";
        #    icmp_type = [
        #      "echo-request"
        #      "echo-reply"
        #      "destination-unreachable"
        #      "packet-too-big"
        #      "time-exceeded"
        #      "bad-header"
        #      "unknown-header-type"
        #      "router-solicitation"
        #      "neighbour-solicitation"
        #      "router-advertisement"
        #      "neighbour-advertisement"
        #    ];
        #    limit = "1000/sec";
        #    family = "ipv6";
        #    target = "ACCEPT";
        #  }
        #  {
        #    _type = "rule";
        #    name = "Allow-ICMPv6-Forward";
        #    src = "wan";
        #    dest = "*";
        #    proto = "icmp";
        #    icmp_type = [
        #      "echo-request"
        #      "echo-reply"
        #      "destination-unreachable"
        #      "packet-too-big"
        #      "time-exceeded"
        #      "bad-header"
        #      "unknown-header-type"
        #    ];
        #    limit = "1000/sec";
        #    family = "ipv6";
        #    target = "ACCEPT";
        #  }
        #  {
        #    _type = "rule";
        #    name = "Allow-IPSec-ESP";
        #    src = "wan";
        #    dest = "lan";
        #    proto = "esp";
        #    target = "ACCEPT";
        #  }
        #  {
        #    _type = "rule";
        #    name = "Allow-ISAKMP";
        #    src = "wan";
        #    dest = "lan";
        #    dest_port = "500";
        #    proto = "udp";
        #    target = "ACCEPT";
        #  }
        #];
      };
      prometheus-node-exporter-lua.main = {
        _type = "prometheus-node-exporter-lua";
        listen_interface = "lan";
      };
    };
  };
}
