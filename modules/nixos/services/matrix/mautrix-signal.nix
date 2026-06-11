{
  flake.modules.nixos.mautrix-signal =
    { config, pkgs, ... }:
    {
      clan.core.vars.generators.mautrix-signal = {
        files."bridge.env" = { };
        runtimeInputs = [ pkgs.pwgen ];
        script = ''
          printf 'PICKLE_KEY=%s\n' "$(pwgen -s 64 1)" > "$out/bridge.env"
        '';
      };

      services.mautrix-signal = {
        enable = true;
        # goolm avoids libolm (marked insecure in nixpkgs)
        package = pkgs.mautrix-signal.override { withGoolm = true; };
        environmentFile = config.clan.core.vars.generators.mautrix-signal.files."bridge.env".path;
        settings = {
          homeserver = {
            # continuwuity on the same host
            address = "http://127.0.0.1:6167";
            domain = "fosskar.de";
          };
          appservice = {
            # bridge url in the generated registration; loopback-only
            address = "http://127.0.0.1:29328";
            hostname = "127.0.0.1";
          };
          bridge.permissions = {
            "fosskar.de" = "user";
            "@fosskar:fosskar.de" = "admin";
          };
          # matrix-side e2ee for portal rooms
          encryption = {
            allow = true;
            default = true;
            pickle_key = "$PICKLE_KEY";
          };
        };
      };

      # one-time: paste signal-registration.yaml into #admins via
      # `!admin appservices register` (continuwuity has no file-based registration)
      systemd.services.mautrix-signal = {
        wants = [ "continuwuity.service" ];
        after = [ "continuwuity.service" ];
      };
    };
}
