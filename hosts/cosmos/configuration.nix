############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
    ./boot.nix
    ./xdg.nix
    ./network.nix
    ./packages.nix
    ./security.nix
    ./services.nix
    ./xserver.nix
    ./user.nix
    ./systemd.nix
    ../../system/nix.nix
    ../../system/audio.nix
    ../../system/fonts.nix
    ../../system/locale.nix
    ../../system/zsh.nix
    ../../system/dconf.nix
    ../../system/gnupg.nix
    ../../system/zram.nix
    ../../system/corectrl.nix
    ../../system/console.nix
    ../../system/nh.nix
    ../../system/filemanager/thunar.nix
    ../../system/gaming/gamemode.nix
    ../../system/gaming/steam.nix
    ../../system/gaming/gamescope.nix
  ];
  console = {
    earlySetup = true;
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  ### DON'T TOUCH!
  system.stateVersion = "23.11";
}
