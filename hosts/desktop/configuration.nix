############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{ ... }:
{
  imports = [
    ./core
    ./gaming
    ./hardware
    ./network
    ./nix
    ./pkgs/packages.nix
    ./programs/corectrl.nix
    ./programs/dconf.nix
    ./programs/direnv.nix
    ./programs/fonts.nix
    ./programs/git.nix
    ./programs/gnupg.nix
    ./programs/home-manager.nix
    ./programs/hyprland.nix
    ./programs/less.nix
    ./programs/seahorse.nix
    ./programs/xdg.nix
    ./programs/xwayland.nix
    ./programs/zsh.nix
    ./security
    ./services/audio.nix
    ./services/fs.nix
    ./services/gnome-services.nix
    ./services/greetd.nix
    ./services/libinput.nix
    ./services/print.nix
    ./services/udev.nix
    ./services/virtualisation.nix
    ./services/zram.nix
  ];

  ### DON'T TOUCH!
  system.stateVersion = "23.11";
}
