_: {
  security.pam = {
    services = {
      login = {
        enableGnomeKeyring = true;
      };
      hyprlock = { };
    };
  };
}
# NOTE: GNOME keyring does not enable a ssh agent/GPG agent in NixOS
