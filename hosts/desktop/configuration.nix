############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{ inputs, ... }:
{
  imports = [
    inputs.chaotic.nixosModules.default
    { nixpkgs.overlays = [ inputs.hyprpanel.overlay ]; }
    ./core
    ./gaming
    ./hardware
    #./kernel # <- this is custom xanmod kernel need too long to build annoying
    ./network
    ./nix
    ./pkgs
    ./programs/shell
    ./programs/corectrl.nix
    ./programs/dconf.nix
    ./programs/fonts.nix
    ./programs/git.nix
    ./programs/gnupg.nix
    ./programs/hyprland.nix
    ./programs/less.nix
    ./programs/seahorse.nix
    ./programs/ssh.nix
    ./programs/xdg.nix
    ./programs/xwayland.nix
    ./secrets/sops-nix.nix
    #./secrets/agenix.nix
    ./security
    ./services/audio.nix
    ./services/earlyoom.nix
    ./services/fs.nix
    ./services/gnome-services.nix
    ./services/greetd.nix
    ./services/lact.nix
    ./services/libinput.nix
    #./services/llm
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
