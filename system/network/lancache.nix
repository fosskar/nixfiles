{...}: {
  virtualisation.oci-containers.containers = {
    lancache = {
      image = "lancachenet/monolithic:latest";
      ports = [
        "80:80/tcp"
        "443:443/tcp"
      ];
      volumes = [
        "/media/lancache/data:/data/cache"
        "/media/lancache/logs:/data/logs"
      ];
    };
    lancache-dns = {
      image = "lancachenet/lancache-dns:latest";
      ports = [
        "53:53/udp"
      ];
      environment = {
        LANCACHE_IP = "192.168.178.91";
        USE_GENERIC_CACHE = "true";
        UPSTREAM_DNS = "1.1.1.2";
      };
    };
  };
}
