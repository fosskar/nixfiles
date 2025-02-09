############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{ lib, ... }:
{
  imports = [
    ./k3s-control-3.nix
    ./hardware-configuration.nix
    ../common/core
    ../common/hardware
    ../common/network
    ../common/nix
    ../common/pkgs
    ../common/programs/zsh.nix
    ../common/secrets
    ../common/security
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking = {
    hostName = "k3s-control-3";
  };

  ### DON'T TOUCH!
  system.stateVersion = "24.11";
}
