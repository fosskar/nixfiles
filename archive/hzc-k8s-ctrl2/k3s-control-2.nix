_: {
  k3s.controlPlane = {
    enable = true;
    nodeName = "k3s-control-2";
    nodeIp = "10.0.0.3";
    serverAddr = "https://10.0.0.2:6443";
    tlsSans = [ "k3s.simonoscar.me" ];
  };
}
