############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{
  lib,
  mylib,
  # inputs,
  ...
}:
{
  imports = [
    # inputs.sops-nix.nixosModules.sops
    ../../modules/vm
    ../../modules/k3s
  ]
  ++ (mylib.scanPaths ./. { exclude = [ "configuration.nix" ]; });

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking = {
    hostName = "k3s-control-2";
  };

  ### DON'T TOUCH!
  system.stateVersion = "24.11";
}
