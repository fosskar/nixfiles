_: {
  k3s.controlPlane = {
    enable = true;
    nodeName = "k3s-control-3";
    nodeIp = "10.0.0.4";
    serverAddr = "https://10.0.0.2:6443";
    tlsSans = [ "k3s.simonoscar.me" ];
  };
}
