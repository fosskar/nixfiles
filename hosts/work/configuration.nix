############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{ ... }:
{
  imports = [
    ./core/boot.nix
    ./core/console.nix
    ./core/dbus.nix
    ./core/locale.nix
    ./core/security.nix
    ./core/users.nix
    ./core/zram.nix
    ./hardware
    ./network
    ./nix
    ./pkgs/packages.nix
    ./programs/dconf.nix
    ./programs/fonts.nix
    ./programs/gnupg.nix
    ./programs/home-manager.nix
    ./programs/hyprland.nix
    ./programs/seahorse.nix
    ./programs/xdg.nix
    ./programs/virt-manager.nix
    ./programs/zsh.nix
    ./services/gnome-services.nix
    ./services/greetd.nix
    ./services/libinput.nix
    ./services/pipewire.nix
    ./services/container.nix
    ./services/udev.nix
    ./services/xserver.nix
  ];

  services = {
    printing.enable = true;
    fstrim.enable = true;
  };

  ### DON'T TOUCH!
  system.stateVersion = "24.05";
}
