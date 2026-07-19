# GL.iNet GL-MT6000 (flint 2) — main router
# TODO: run `nix run .#openwrt-fetch-router` to dump current config, then adjust below
{
  host = "192.168.10.1";

  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA openpgp:0xDA6712BE"
  ];

  packages = [
    "adguardhome"

    "usteer"
    "luci-app-usteer"

    "wpad-wolfssl"

    "irqbalance"

    "telegraf-full"

    "unbound-daemon"
    "unbound-control"
    "unbound-control-setup"
    "luci-app-unbound"

    "sqm-scripts"
    "luci-app-sqm"

    "zram-swap"

    "openwisp-config"
    "openwisp-monitoring"
    "luci-app-openwisp"
  ];

  removePackages = [
    "wpad-basic-wolfssl" # gets replaced by full wpad-wolfssl package, because some options missing that needed by DAWN
  ];

  externalPackages = [
    {
      name = "beszel-agent";
      installCommand = "wget -qO- https://github.com/vernette/beszel-agent-openwrt/raw/master/install.sh | sh";
    }
  ];

  files = {
    "/etc/unbound/unbound_srv.conf" = ./files/unbound_srv.conf;
    "/etc/unbound/unbound_ext.conf" = ./files/unbound_ext.conf;
    "/etc/crontabs/root" = ./files/crontabs-root;
    "/etc/telegraf.conf" = ./files/telegraf.conf;
    "/etc/sysctl.d/99-hardening.conf" = ./files/sysctl-hardening.conf;
    "/usr/bin/netboot-update" = ./files/netboot-update;
    "/etc/sysupgrade.conf" = ./files/sysupgrade.conf;
  };

  reload = [
    "telegraf"
    "sysctl"
    "unbound"
  ];

  uci = {
    secrets.sops.files = [ ../secrets.yaml ];

    settings = {
      attendedsysupgrade.client = {
        _type = "client";
        advanced_mode = "1";
        login_check_for_upgrades = "1";
      };

      beszel-agent.agent = {
        _type = "agent";
        enabled = "1";
        port = "45876";
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHN601z/tNqh+R7x9JaCDayBioT2aQs1tEGv0tOSF/wu";
        hub_url = "https://beszel.nx3.eu";
        token = "@beszel_token_router@";
      };

      openwisp.http = {
        _type = "controller";
        url = "https://opensoho.nx3.eu";
        verify_ssl = 1;
        shared_secret = "@opensoho_shared_secret@";
      };

      system.system = [
        {
          _type = "system";
          hostname = "openwrt";
        }
      ];

      usteer.usteer = {
        _type = "usteer";
        roam_scan_snr = "-65";
        signal_diff_threshold = "8";
      };

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
              "lan2"
              "lan3"
              "lan4"
              "lan5"
            ];
          }
          {
            _type = "device";
            name = "br-srv";
            type = "bridge";
            ports = [ "lan1" ];
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
          ip6addr = "fd8a:2e59:7bfd::1/64";
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
        srv = {
          _type = "interface";
          device = "br-srv";
          proto = "static";
          ipaddr = "192.168.20.1/24";
          ip6addr = "fd8a:2e59:7bfd:20::1/64";
          ip6assign = "60";
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
            notinterface = [ "wan" ];
            # --- netboot.xyz PXE ---
            enable_tftp = "1";
            tftp_root = "/srv/tftp";
            dhcp_boot = "netboot.xyz.efi";
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
        srv = {
          _type = "dhcp";
          interface = "srv";
          start = "100";
          limit = "50";
          leasetime = "12h";
          dhcpv4 = "server";
          dhcpv6 = "server";
          ra = "server";
          ra_flags = [
            "managed-config"
            "other-config"
          ];
          dns = "fd8a:2e59:7bfd:20::1";
        };

        nixbox_bmc = {
          _type = "host";
          name = "nixbox-bmc";
          ip = "192.168.20.205";
          mac = "9C:6B:00:A9:15:CC";
        };
        openwrt_ap = {
          _type = "host";
          name = "openwrt-ap";
          ip = "192.168.10.2";
          mac = "64:DD:68:37:2A:32";
        };
        homeassistant = {
          _type = "host";
          name = "homeassistant";
          ip = "192.168.10.50";
          mac = "20:F8:3B:01:57:AB";
        };
        printer = {
          _type = "host";
          name = "HPF4DB54";
          ip = "192.168.10.153";
          mac = "E0:73:E7:F4:DB:55";
        };
        tl_sg108pe = {
          _type = "host";
          name = "tl-sg108pe";
          ip = "192.168.10.10";
          mac = "DC:62:79:90:0E:B2";
        };
        jetkvm_ha = {
          _type = "host";
          name = "jetkvm-ha";
          ip = "192.168.10.30";
          mac = "30:52:53:0A:4F:32";
        };
        jetkvm_nixworker = {
          _type = "host";
          name = "jetkvm-nixworker";
          ip = "192.168.20.211";
          mac = "30:52:53:02:BF:49";
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
        };
        auth_icann = {
          _type = "zone";
          enabled = "1";
        };
      };

      # sqm needs software offloading only (flow_offloading_hw incompatible)
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
            name = "srv";
            network = [ "srv" ];
            input = "REJECT";
            output = "ACCEPT";
            forward = "REJECT";
          }
          {
            _type = "zone";
            name = "iot";
            network = [ "iot" ];
            input = "REJECT";
            output = "ACCEPT";
            forward = "REJECT";
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
          {
            _type = "forwarding";
            src = "srv";
            dest = "wan";
          }
          {
            _type = "forwarding";
            src = "lan";
            dest = "srv";
          }
        ];
        redirect = [
          # this intercepts every connection and forces it to use the router for DNS, so that adguard home can filter DNS requests and block ads, trackers, etc. even if the client has a custom DNS server configured
          {
            _type = "redirect";
            target = "DNAT";
            name = "force dns interception";
            proto = [
              "tcp"
              "udp"
            ];
            src = "lan";
            src_dport = "53";
            dest_ip = "192.168.10.1";
            dest_port = "53";
            family = "ipv4";
          }
          {
            _type = "redirect";
            target = "DNAT";
            name = "force dns interception - iot";
            proto = [
              "tcp"
              "udp"
            ];
            src = "iot";
            src_dport = "53";
            dest_ip = "192.168.10.1";
            dest_port = "53";
            family = "ipv4";
          }
          {
            _type = "redirect";
            target = "DNAT";
            name = "force dns interception - srv";
            proto = [
              "tcp"
              "udp"
            ];
            src = "srv";
            src_dport = "53";
            dest_ip = "192.168.20.1";
            dest_port = "53";
            family = "ipv4";
          }
          {
            _type = "redirect";
            target = "DNAT";
            name = "force dns interception v6";
            proto = [
              "tcp"
              "udp"
            ];
            src = "lan";
            src_dport = "53";
            dest_ip = "fd8a:2e59:7bfd::1";
            dest_port = "53";
            family = "ipv6";
          }
          {
            _type = "redirect";
            target = "DNAT";
            name = "force dns interception - iot v6";
            proto = [
              "tcp"
              "udp"
            ];
            src = "iot";
            src_dport = "53";
            dest_ip = "fd8a:2e59:7bfd::1";
            dest_port = "53";
            family = "ipv6";
          }
          {
            _type = "redirect";
            target = "DNAT";
            name = "force dns interception - srv v6";
            proto = [
              "tcp"
              "udp"
            ];
            src = "srv";
            src_dport = "53";
            dest_ip = "fd8a:2e59:7bfd:20::1";
            dest_port = "53";
            family = "ipv6";
          }
        ];
        iot_dhcp = {
          _type = "rule";
          name = "Allow-IoT-DHCP";
          src = "iot";
          proto = "udp";
          dest_port = "67-68";
          target = "ACCEPT";
        };
        iot_dns = {
          _type = "rule";
          name = "Allow-IoT-DNS";
          src = "iot";
          proto = [
            "udp"
            "tcp"
          ];
          dest_port = "53";
          target = "ACCEPT";
        };
        block_dot = {
          _type = "rule";
          name = "Block-DoT-Bypass";
          src = "*";
          dest = "wan";
          proto = [
            "tcp"
            "udp"
          ];
          dest_port = "853";
          target = "REJECT";
        };
        srv_dhcp = {
          _type = "rule";
          name = "Allow-Srv-DHCP";
          src = "srv";
          proto = "udp";
          dest_port = "67-68";
          target = "ACCEPT";
        };
        srv_dns = {
          _type = "rule";
          name = "Allow-Srv-DNS";
          src = "srv";
          proto = [
            "udp"
            "tcp"
          ];
          dest_port = "53";
          target = "ACCEPT";
        };
        srv_ssh_router = {
          _type = "rule";
          name = "Allow-Srv-SSH-Router";
          src = "srv";
          proto = "tcp";
          dest_port = "22";
          target = "ACCEPT";
        };
        srv_ssh_ap = {
          _type = "rule";
          name = "Allow-Srv-SSH-AP";
          src = "srv";
          dest = "lan";
          dest_ip = "192.168.10.2";
          proto = "tcp";
          dest_port = "22";
          target = "ACCEPT";
        };
        srv_telegraf = {
          _type = "rule";
          name = "Allow-Srv-Telegraf";
          src = "srv";
          proto = "tcp";
          dest_port = "9273";
          target = "ACCEPT";
        };
        srv_homeassistant = {
          _type = "rule";
          name = "Allow-Srv-HomeAssistant";
          src = "srv";
          dest = "lan";
          dest_ip = "192.168.10.50";
          proto = "tcp";
          dest_port = "8123";
          target = "ACCEPT";
        };
        srv_icmpv6 = {
          _type = "rule";
          # NDP runs over ICMPv6; without this the router rejects neighbor
          # advertisements from srv hosts and all their IPv6 dies (IPv4
          # survives because ARP is not IP and bypasses the firewall).
          name = "Allow-Srv-ICMPv6";
          src = "srv";
          proto = "icmp";
          family = "ipv6";
          limit = "1000/sec";
          target = "ACCEPT";
        };
        srv_dhcpv6 = {
          _type = "rule";
          name = "Allow-Srv-DHCPv6";
          src = "srv";
          proto = "udp";
          dest_port = "547";
          family = "ipv6";
          target = "ACCEPT";
        };
        iot_icmpv6 = {
          _type = "rule";
          name = "Allow-IoT-ICMPv6";
          src = "iot";
          proto = "icmp";
          family = "ipv6";
          limit = "1000/sec";
          target = "ACCEPT";
        };
        iot_dhcpv6 = {
          _type = "rule";
          name = "Allow-IoT-DHCPv6";
          src = "iot";
          proto = "udp";
          dest_port = "547";
          family = "ipv6";
          target = "ACCEPT";
        };
        iot_mqtt = {
          _type = "rule";
          name = "Allow-IoT-MQTT-HomeAssistant";
          src = "iot";
          dest = "lan";
          dest_ip = "192.168.10.50";
          proto = "tcp";
          dest_port = "1883";
          target = "ACCEPT";
        };
      };
    };
  };
}
