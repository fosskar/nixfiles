# 802.11r/k + usteer roaming only works when these match on every radio of every device
{
  module = {
    packages = [
      "usteer"
      "luci-app-usteer"

      "wpad-wolfssl"
    ];

    removePackages = [ "wpad-basic-wolfssl" ];

    uci.settings.usteer.usteer = {
      _type = "usteer";
      roam_scan_snr = "-65";
      signal_diff_threshold = "8";
    };
  };

  wifiIface = device: {
    _type = "wifi-iface";
    inherit device;
    network = "lan";
    mode = "ap";
    ssid = "@wifi_ssid_main@";
    key = "@wifi_password_main@";
    encryption = "sae-mixed";
    ieee80211r = "1";
    ieee80211k = "1";
    bss_transition = "1";
  };
}
