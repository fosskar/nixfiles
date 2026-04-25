{
  flake.modules.nixos.ups =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.nut ];

      clan.core.vars.generators.ups = {
        files.password.secret = true;
        runtimeInputs = [ pkgs.openssl ];
        script = "openssl rand -hex 32 > $out/password";
      };

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
          passwordFile = config.clan.core.vars.generators.ups.files.password.path;
          upsmon = "primary";
        };

        upsmon = {
          enable = true;
          monitor."eaton-ellipse" = {
            user = "upsmon";
            type = "primary";
            powerValue = 1;
            passwordFile = config.clan.core.vars.generators.ups.files.password.path;
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

      systemd.services.upsdrv = {
        unitConfig.StartLimitIntervalSec = 0;
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };
    };
}
