_: {
  services.cockpit = {
    enable = true;
    openFirewall = true;
    port = 9090;
    settings = {
      WebService = {
        AllowUnencrypted = true;
        Origins = "http://cockpit.simonoscar.me http://k3s-control-1 http://k3s-control-1 http://k3s-control-1 http://100.100.10.2 http://100.100.10.3 http://100.100.10.4 http://10.0.0.2 http://10.0.0.3 http://10.0.0.4";
        AllowMultiHost = true;
      };
    };
  };
}
