############################################################################################
## this is the systems configuration file                                                 ##
## use this to configure the system environment, it replaces /etc/nixos/configuration.nix ##
############################################################################################
{...}: {
  imports = [
    ../../system/core/boot.nix
    ../../system/core/console.nix
    ../../system/core/dbus.nix
    ../../system/core/locale.nix
    ../../system/core/security.nix
    ../../system/core/users.nix
    ../../system/core/zram.nix
    ../../system/gaming/gamemode.nix
    ../../system/gaming/gamescope.nix
    ../../system/gaming/steam.nix
    ../../system/hardware/amdgpu.nix
    ../../system/hardware/bluetooth.nix
    ../../system/hardware/fwupd.nix
    ../../system/network
    ../../system/network/tailscale.nix
    ../../system/nix
    ../../system/programs/corectrl.nix
    ../../system/programs/dconf.nix
    ../../system/programs/fonts.nix
    ../../system/programs/gnupg.nix
    ../../system/programs/home-manager.nix
    ../../system/programs/hyprland.nix
    ../../system/programs/seahorse.nix
    ../../system/programs/xdg.nix
    ../../system/programs/zsh.nix
    ../../system/services/gnome-services.nix
    ../../system/services/greetd.nix
    ../../system/services/libinput.nix
    #../../system/services/ollama.nix # holy shit need to build HOURS
    ../../system/services/pipewire.nix
    ../../system/services/udev.nix
    ../../system/services/virtualisation.nix
    ../../system/services/xserver.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos";

  services = {
    printing.enable = true;
    fstrim.enable = true;
    thermald.enable = true;
  };

  ### DON'T TOUCH!
  system.stateVersion = "23.11";
}
