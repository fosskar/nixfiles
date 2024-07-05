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
    ./gaming/gamemode.nix
    ./gaming/gamescope.nix
    ./gaming/steam.nix
    ./hardware
    ./network
    ./network/tailscale.nix
    ./nix
    ./pkgs/packages.nix
    ./programs/corectrl.nix
    ./programs/dconf.nix
    ./programs/fonts.nix
    ./programs/gnupg.nix
    ./programs/home-manager.nix
    ./programs/hyprland.nix
    #./programs/seahorse.nix # not needed without gnome-keyring
    ./programs/xdg.nix
    ./programs/zsh.nix
    #./services/gnome-services.nix #WHY?
    ./services/greetd.nix
    ./services/libinput.nix
    ./services/pipewire.nix
    ./services/podman.nix
    ./services/powerprofile.nix
    ./services/udev.nix
    ./services/xserver.nix
  ];

  services = {
    printing.enable = true;
    fstrim.enable = true;
  };

  ### DON'T TOUCH!
  system.stateVersion = "23.11";
}
