############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{ lib, ... }:
{
  imports = [
    ./k3s-master-test-1.nix
    ./hardware-configuration.nix
    ../common/modules/k3sModule.nix
    ../common/core
    ../common/hardware
    ../common/network
    ../common/nix
    ../common/pkgs
    ../common/programs/zsh.nix
    ../common/secrets
    ../common/security
    ../common/services/podman.nix
    ../common/services/ssh.nix
    ../common/services/udev.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  networking = {
    hostName = "k3s-master-test-1";
  };

  ### DON'T TOUCH!
  system.stateVersion = "24.05";
}
