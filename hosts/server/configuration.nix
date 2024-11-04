############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{ lib, ... }:
{
  imports = [
    ./core
    ./hardware
    ./network
    ./nix
    ./pkgs
    ./programs/gnupg.nix
    ./programs/zsh.nix
    ./secrets
    ./security
    # ./services/kubernetes/helm.nix
    ./services/kubernetes/k3s.nix
    ./services/podman.nix
    ./services/power.nix
    ./services/ssh.nix
    ./services/udev.nix
    ./services/zram.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  ### DON'T TOUCH!
  system.stateVersion = "24.05";
}
