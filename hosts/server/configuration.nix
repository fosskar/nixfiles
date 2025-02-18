############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
_: {
  imports = [
    ./hardware/hardware-configuration.nix
    ./core
    ./hardware
    ./network
    ./nix
    ./pkgs
    ./programs
    ./secrets
    ./security
    ./proxmox.nix
  ];

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  networking = {
    hostName = "proxmox-nixos";
    hostId = "01c7a6ca";
  };

  ### DON'T TOUCH!
  system.stateVersion = "24.11";
}
