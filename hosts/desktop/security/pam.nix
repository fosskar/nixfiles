_: {
  security.pam = {
    services = {
      login = {
        enableGnomeKeyring = true;
      };
      hyprlock = {
        text = "auth include login";
        enableGnomeKeyring = true;
      };
      greetd = {
        enableGnomeKeyring = true;
      };
    };
  };
}
