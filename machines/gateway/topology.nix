_: {
  topology.self = {
    icon = "devices.cloud-server";
    hardware.info = "hetzner vps";
    interfaces.wan = {
      addresses = [ "138.201.155.21" ];
      network = "wan";
    };
  };
}
