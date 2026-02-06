{
  networking = {
    hostName = "clawbox";

    useDHCP = false;
    defaultGateway = {
      address = "192.168.10.1";
      interface = "enp1s0";
    };
    nameservers = [ "192.168.10.1" ];

    interfaces.enp1s0.ipv4.addresses = [
      {
        address = "192.168.10.90";
        prefixLength = 24;
      }
    ];
  };
}
