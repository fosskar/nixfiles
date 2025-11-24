_: {
  security.pam = {
    services = {
      login = {
        enableGnomeKeyring = true;
      };
      hyprlock = {
        enableGnomeKeyring = true;
      };
      greetd = {
        enableGnomeKeyring = true;
      };
      greetd-password = {
        enableGnomeKeyring = true;
      };
      cosmic-greeter = {
        enableGnomeKeyring = true;
      };
    };
  };
}
