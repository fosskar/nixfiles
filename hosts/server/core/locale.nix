{ lib, config, ... }:
{
  options.locale = {
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Berlin";
      description = "The system's time zone.";
    };

    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "The default system locale.";
    };

    extraLocaleSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        LC_ADDRESS = "de_DE.UTF-8";
        LC_IDENTIFICATION = "de_DE.UTF-8";
        LC_MEASUREMENT = "de_DE.UTF-8";
        LC_MONETARY = "de_DE.UTF-8";
        LC_NAME = "de_DE.UTF-8";
        LC_NUMERIC = "de_DE.UTF-8";
        LC_PAPER = "de_DE.UTF-8";
        LC_TELEPHONE = "de_DE.UTF-8";
        LC_TIME = "de_DE.UTF-8";
      };
      description = "Additional locale settings.";
    };

    keyboardLayout = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Keyboard layout settings.";
    };
  };

  config = {
    time.timeZone = config.locale.timeZone;

    i18n.defaultLocale = config.locale.defaultLocale;
    i18n.extraLocaleSettings = config.locale.extraLocaleSettings;

    services.xserver.xkb = {
      layout = config.locale.keyboardLayout.layout or "de";
      variant = config.locale.keyboardLayout.variant or "";
      options = config.locale.keyboardLayout.options or "";
    };
  };
}
