############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{ mylib, ... }:
{
  imports = [
    ../../modules/shared
  ]
  ++ (mylib.scanPaths ./. { exclude = [ "configuration.nix" ]; });

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  networking = {
    hostId = "8425e349";
  };

  ### DON'T TOUCH!
  system.stateVersion = "24.11";
}
