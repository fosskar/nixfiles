{ ... }:
{
  imports = [
    ../hosts/desktop/core/console.nix
    ../hosts/desktop/core/dbus.nix
    ../hosts/desktop/core/locale.nix
    ../hosts/desktop/core/users.nix
    ../hosts/desktop/hardware/fwupd.nix
    ../hosts/desktop/network
    ../hosts/desktop/network/tailscale.nix
    ../hosts/desktop/nix
    ../hosts/desktop/programs/dconf.nix
    ../hosts/desktop/programs/fonts.nix
    ../hosts/desktop/programs/gnupg.nix
    ../hosts/desktop/programs/home-manager.nix
    ../hosts/desktop/programs/hyprland.nix
    ../hosts/desktop/programs/seahorse.nix
    ../hosts/desktop/programs/xdg.nix
    ../hosts/desktop/programs/zsh.nix
    ../hosts/desktop/services/gnome-services.nix
    ../hosts/desktop/services/greetd.nix
    ../hosts/desktop/services/libinput.nix
    ../hosts/desktop/services/audio.nix
    ../hosts/desktop/services/udev.nix
  ];

  system.stateVersion = "23.11";
}
