_: {
  _class = "clan.service";
  manifest.name = "ups";
  manifest.description = "NUT UPS monitoring: usb-attached primary serving remote secondaries";
  manifest.readme = "NUT UPS monitoring; usb-attached primary serves remote secondaries over the LAN";

  roles.primary = {
    description = "usb-attached UPS host: runs the driver, upsd and the primary upsmon";

    perInstance = _: {
      nixosModule =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          environment.systemPackages = [ pkgs.nut ];

          # nut config files don't need to be world-readable; silences upsd
          # "world readable" warning. upsmon.conf and upsd.users already 0400.
          environment.etc = {
            "nut/nut.conf".mode = lib.mkForce "0640";
            "nut/ups.conf".mode = lib.mkForce "0640";
            "nut/upsd.conf".mode = lib.mkForce "0640";
            "nut/upssched.conf".mode = lib.mkForce "0640";
          };

          clan.core.vars.generators.ups = {
            share = true;
            files.password.secret = true;
            runtimeInputs = [ pkgs.openssl ];
            script = "openssl rand -hex 32 > $out/password";
          };

          power.ups = {
            enable = true;
            mode = "netserver";

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

            # remote secondaries authenticate as this user
            users.upsmon-secondary = {
              passwordFile = config.clan.core.vars.generators.ups.files.password.path;
              upsmon = "secondary";
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
                # dual-stack; nixbox.lan resolves ipv6-only on secondaries
                { address = "::"; }
              ];
            };
          };

          # expose upsd to LAN secondaries only
          networking.firewall.interfaces.bond0.allowedTCPPorts = [ 3493 ];

          systemd.services = {
            upsdrv = {
              after = lib.mkForce [ ];
              before = [
                "upsd.service"
                "upsmon.service"
              ];
              unitConfig.StartLimitIntervalSec = 0;
              serviceConfig = {
                Restart = "on-failure";
                RestartSec = "10s";
              };
            };

            upsd = {
              after = lib.mkForce [
                "network.target"
                "upsdrv.service"
              ];
              # wants, not requires: usb race can fail upsdrv; failed Requires start is never retried
              wants = [ "upsdrv.service" ];
              before = [ "upsmon.service" ];
              # restart covers runtime crashes only (hence wants above)
              unitConfig.StartLimitIntervalSec = 0;
              serviceConfig = {
                Restart = "on-failure";
                RestartSec = "10s";
              };
            };

            upsmon = {
              after = lib.mkForce [
                "network.target"
                "upsd.service"
              ];
              requires = [ "upsd.service" ];
            };
          };
        };
    };
  };

  roles.secondary = {
    description = "remote machine powered by the UPS: monitors the primary and shuts down on low battery";

    perInstance =
      { roles, ... }:
      {
        nixosModule =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            primaryMachines = lib.attrNames (roles.primary.machines or { });
            primaryHost =
              if primaryMachines == [ ] then
                throw "ups: secondary role requires a primary machine"
              else
                "${lib.head primaryMachines}.lan";
          in
          {
            environment.systemPackages = [ pkgs.nut ];

            environment.etc = {
              "nut/nut.conf".mode = lib.mkForce "0640";
            };

            clan.core.vars.generators.ups = {
              share = true;
              files.password.secret = true;
              runtimeInputs = [ pkgs.openssl ];
              script = "openssl rand -hex 32 > $out/password";
            };

            power.ups = {
              enable = true;
              mode = "netclient";

              upsmon = {
                enable = true;
                monitor."eaton-ellipse" = {
                  user = "upsmon-secondary";
                  type = "secondary";
                  powerValue = 1;
                  passwordFile = config.clan.core.vars.generators.ups.files.password.path;
                  system = "eaton-ellipse@${primaryHost}";
                };
              };
            };
          };
      };
  };
}
