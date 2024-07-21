{ ... }:
{
  time.timeZone = "Europe/Berlin";

  services.xserver.xkb = {
    layout = "de";
    variant = "";
    options = "";
  };

  i18n =
    let
      defaultLocale = "en_US.UTF-8";
      de = "de_DE.UTF-8";
    in
    {
      inherit defaultLocale;

      extraLocaleSettings = {
        LANGUAGE = defaultLocale;
        LANG = defaultLocale;
        LC_ALL = de;
        LC_ADDRESS = de;
        LC_IDENTIFICATION = de;
        LC_MEASUREMENT = de;
        LC_MONETARY = de;
        LC_NAME = de;
        LC_NUMERIC = de;
        LC_PAPER = de;
        LC_TELEPHONE = de;
        LC_TIME = de;
      };
      supportedLocales = [
        "en_US.UTF-8/UTF-8"
        "de_DE.UTF-8/UTF-8"
      ];
    };
}
