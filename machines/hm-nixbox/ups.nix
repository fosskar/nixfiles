{ config, ... }:
{
  power.ups = {
    enable = true;
    mode = "standalone";

    ups."eaton-ellipse" = {
      driver = "usbhid-ups";
      port = "auto";
      description = "Eaton Ellipse PRO";
      directives = [
        "vendorid = 0463"
        "productid = FFFF"
      ];
    };

    users.upsmon = {
      passwordFile = config.sops.secrets."admin-password".path;
      upsmon = "primary";
    };

    upsmon = {
      enable = true;
      monitor."eaton-ellipse" = {
        user = "upsmon";
        type = "primary";
        powerValue = 1;
        passwordFile = config.sops.secrets."admin-password".path;
        system = "eaton-ellipse@localhost";
      };
    };

    upsd = {
      enable = true;
      listen = [
        { address = "127.0.0.1"; }
      ];
    };
  };
}
