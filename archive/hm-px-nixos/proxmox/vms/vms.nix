{ inputs, ... }:
{
  imports = [
    inputs.proxmox-nixos.nixosModules.declarative-vms
  ];

  networking.hostName = "k3s-control-1";
  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  boot.loader.grub.devices = [ "nodev" ];

  #isoImage.isoBaseName = lib.mkForce "nixos-offline-installer";
  #image.baseName = lib.mkForce "nixos-offline-installer";

  virtualisation.proxmox = {
    node = "proxmox-nixos";
    autoInstall = true;
    vmid = 101;
    bios = "ovmf"; # yes please no seahorse or seabig thing
    memory = 16384;
    kvm = true;
    cores = 6;
    sockets = 1;
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
  system.stateVersion = "24.11";
}
