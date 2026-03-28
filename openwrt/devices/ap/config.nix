# Zyxel NWA50AX Pro AP — dumb AP mode
# static ip: 192.168.10.2, gateway: 192.168.10.1 (main router)
{
  host = "192.168.10.2";

  packages = [
    ## broken & overkill
    #"dawn"
    #"luci-app-dawn"
    "usteer"
    "luci-app-usteer"

    "wpad-wolfssl"
  ];

  removePackages = [
    "wpad-basic-wolfssl" # gets replaced by full wpad-wolfssl package, because some options missing that needed by DAWN
  ];

  disableServices = [
    "dnsmasq"
    "firewall"
    "odhcpd"
    "radius"
  ];

  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA openpgp:0xDA6712BE"
  ];

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
        token = "@beszel_token_ap@";
      };

      system.system = [
        {
          _type = "system";
          hostname = "openwrt-ap";
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
          packet_steering = "1";
        };
        device = [
          {
            _type = "device";
            name = "br-lan";
            type = "bridge";
            ports = [ "eth0" ];
          }
        ];
        lan = {
          _type = "interface";
          device = "br-lan";
          proto = "static";
          ipaddr = "192.168.10.2";
          netmask = "255.255.255.0";
          gateway = "192.168.10.1";
          dns = "192.168.10.1";
        };
      };

      # disable DHCP because its a dumb AP, the main router will handle DHCP and routing
      dhcp = {
        lan = {
          _type = "dhcp";
          interface = "lan";
          ignore = "1";
        };
      };

      wireless = {
        radio0 = {
          _type = "wifi-device";
          type = "mac80211";
          path = "platform/soc/18000000.wifi";
          band = "2g";
          channel = "1";
          htmode = "HE20";
          cell_density = "1";
          country = "DE";
        };
        main0_2g = {
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

        radio1 = {
          _type = "wifi-device";
          type = "mac80211";
          path = "platform/soc/18000000.wifi+1";
          band = "5g";
          channel = "44";
          htmode = "HE80";
          cell_density = "1";
          country = "DE";
        };
        main1_5g = {
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

      prometheus-node-exporter-lua.main = {
        _type = "prometheus-node-exporter-lua";
        listen_interface = "lan";
      };
    };
  };
}
