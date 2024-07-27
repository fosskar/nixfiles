{ ... }:
{
  security.pam = {
    services = {
      hyprlock = {
        text = "auth include login";
        enableGnomeKeyring = true;
      };
      ags = { };
      login = {
        enableGnomeKeyring = true;
      };

      greetd = {
        enableGnomeKeyring = true;
      };

      tuigreet = {
        enableGnomeKeyring = true;
      };
    };
  };
}
