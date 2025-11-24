_: {
  services.proxmox-ve.vms = {
    k3s-control-1 = {
      vmid = 101;
      acpi = true;
      bios = "ovmf"; # yes please no seahorse or seabig thing
      memory = 16384; # 18GB RAM
      description = "";
      cores = 6;
      sockets = 1;
      kvm = true;
      hotplug = [
        "network"
        "disk"
        "cpu"
        "memory"
      ];
      hugepages = "1024";
      machine = {
        type = "q35";
        viommu = "virtio";
      };
      net = [
        {
          model = "virtio";
          bridge = "vmbr0";
          firewall = false;
        }
      ];
      numa = true;
      onboot = true;
      ostype = "l26";
      scsi = [
        {
          file = "local:100";
          format = "raw";
          model = "virtio";
          size = "100G";
          cache = "none";
          discard = "off";
          iothread = true;
        }
      ];
      scsihw = "virtio-scsi-single";
      unique = true;
    };
    #k3s-control-2 = {
    #};
    #k3s-control-3 = {
    #};
  };
}
