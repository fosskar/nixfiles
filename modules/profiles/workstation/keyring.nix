{ lib, config, ... }:
{
  # gnome-keyring - secret storage for apps using freedesktop secrets API
  # browsers and many apps use this for credential storage
  services.gnome.gnome-keyring.enable = lib.mkDefault true;

  # seahorse - GUI for managing keyring secrets and keys
  programs.seahorse.enable = lib.mkDefault true;

  # unlock keyring on login for greeters/lock screens
  security.pam.services = {
    login.enableGnomeKeyring = lib.mkDefault true;
    greetd.enableGnomeKeyring = lib.mkIf config.services.greetd.enable true;
    hyprlock.enableGnomeKeyring = lib.mkIf config.programs.hyprlock.enable true;
    cosmic-greeter.enableGnomeKeyring = lib.mkIf config.services.displayManager.cosmic-greeter.enable true;
  };
}
