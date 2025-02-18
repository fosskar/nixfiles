{
  pkgs,
  modulesPath,
  lib,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  proxmox = {
    # Reference: https://pve.proxmox.com/wiki/Qemu/KVM_Virtual_Machines#qm_virtual_machines_settings
    qemuConf = {
      # EFI support
      bios = "ovmf";
      cores = 6;
      memory = 14336;
      net0 = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=1";
      virtio0 = "local-lvm:vm-9999-disk-0";
      diskSize = 102400; # 100gb
    };
    qemuExtraConf = {
      # start the VM automatically on boot
      # onboot = "1";
      cpu = "host";
      tags = "nixos";
    };
  };

  swapDevices = [ ];

  virtualisation.diskSize = lib.mkForce 102400;

  #Provide a default hostname
  networking = {
    hostName = "";
    firewall.allowedTCPPorts = [ 22 ];
    dhcpcd.enable = false;
    enableIPv6 = false;
    useHostResolvConf = false;
  };

  # Use the boot drive for grub
  boot = {
    growPartition = lib.mkDefault true;
    loader.grub = {
      enable = lib.mkForce true;
      devices = [ "nodev" ];
    };
  };

  # Enable mDNS for `hostname.local` addresses
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  # Some sane packages we need on every system
  environment.systemPackages = with pkgs; [
    vim # for emergencies
    gitMinimal # for pulling nix flakes
  ];

  # Enable ssh
  services = {
    cloud-init = {
      enable = true;
      network.enable = true;
    };
    qemuGuest.enable = lib.mkDefault true;
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };
  programs.ssh.startAgent = true;

  # add authorizedkey for root user
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1zarKMo5sVMAn5f0ew4j82vHlkUOLp6BcdODKaUc85 simonoscr@proton.me"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = lib.mkDefault "24.11";
}
