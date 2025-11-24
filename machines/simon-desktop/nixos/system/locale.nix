_: {
  time.timeZone = "Europe/Berlin";

  i18n =
    let
      de = "de_DE.UTF-8";
      en = "en_US.UTF-8";
    in
    {
      defaultLocale = en;

      extraLocaleSettings = {
        LANGUAGE = en;
        LANG = en;
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
  services.xserver.xkb = {
    layout = "de";
    model = "pc105";
    variant = "";
    options = "";
  };
}
