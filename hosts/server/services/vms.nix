_: {
  # Define VMs
  virtualisation.qemu.vms = {
    vm1 = {
      memorySize = 2048; # Memory in MB
      diskSize = 20; # Disk size in GB
      diskImage = /var/lib/libvirt/images/vm1.qcow2; # Disk image path
      vcpu = 1;
      # Define the network
      network = {
        enable = true;
        type = "user";
      };
    };
    vm2 = {
      /*
      ...similar configuration...
      */
    };
    vm3 = {
      /*
      ...similar configuration...
      */
    };
  };
}
