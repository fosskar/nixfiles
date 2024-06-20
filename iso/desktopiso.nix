{ ... }:
{
  imports = [
    ../hosts/desktop/core/console.nix
    ../hosts/desktop/core/dbus.nix
    ../hosts/desktop/core/locale.nix
    ../hosts/desktop/core/security.nix
    ../hosts/desktop/core/users.nix
    ../hosts/desktop/core/zram.nix
    ../hosts/desktop/gaming/gamemode.nix
    ../hosts/desktop/gaming/gamescope.nix
    ../hosts/desktop/gaming/steam.nix
    ../hosts/desktop/hardware/amdgpu.nix
    ../hosts/desktop/hardware/bluetooth.nix
    ../hosts/desktop/hardware/fwupd.nix
    ../hosts/desktop/hardware/wooting.nix
    ../hosts/desktop/network
    ../hosts/desktop/network/tailscale.nix
    ../hosts/desktop/nix
    ../hosts/desktop/programs/corectrl.nix
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
    ../hosts/desktop/services/pipewire.nix
    ../hosts/desktop/services/podman.nix
    ../hosts/desktop/services/powerprofile.nix
    ../hosts/desktop/services/udev.nix
    ../hosts/desktop/services/xserver.nix
  ];

  services = {
    printing.enable = true;
    fstrim.enable = true;
  };

  system.stateVersion = "23.11";
}
