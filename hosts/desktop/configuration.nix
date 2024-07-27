############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{ inputs, ... }:
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
    ./programs/hyprland.nix
    ./programs/less.nix
    ./programs/seahorse.nix
    ./programs/xdg.nix
    ./programs/xwayland.nix
    ./programs/zsh.nix
    ./secrets
    ./security
    ./services/audio.nix
    ./services/earlyoom.nix
    ./services/fs.nix
    ./services/gnome-services.nix
    ./services/greetd.nix
    ./services/libinput.nix
    ./services/llm/ollama.nix
    ./services/power.nix
    ./services/printing.nix
    ./services/systemd.nix
    ./services/udev.nix
    ./services/udiskie.nix
    ./services/virtualisation.nix
    ./services/zram.nix
    ../../home/home-manager.nix
  ];

  ### DON'T TOUCH!
  system.stateVersion = "23.11";
}
