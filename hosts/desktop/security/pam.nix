_: {
  security.pam = {
    services = {
      login = {
        enableGnomeKeyring = true;
      };
      hyprlock = {
        enableGnomeKeyring = true;
      };
    };
  };
}
# NOTE: GNOME keyring does not enable a ssh agent/GPG agent in NixOS
