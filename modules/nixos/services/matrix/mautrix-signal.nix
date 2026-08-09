{
  flake.modules.nixos.matrix =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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
        package = (pkgs.mautrix-signal.override { withGoolm = true; }).overrideAttrs {
          # Continuwuity rejects simultaneous stable and legacy MSC4190 device parameters.
          postConfigure = ''
            substituteInPlace vendor/maunium.net/go/mautrix/url.go \
              --replace-fail 'query.Set("org.matrix.msc3202.device_id", string(cli.DeviceID))' ""
          '';
        };
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
            msc4190 = true;
            pickle_key = "$PICKLE_KEY";
          };
        };
      };

      # --- backup ---

      # the db holds the signal device link and the portal mappings.
      # signal-registration.yaml is the one-time manual step below, so losing it
      # means re-registering the appservice; config.yaml comes from nix.
      clan.core.state.mautrix-signal = {
        folders = [ "/var/backup/mautrix-signal" ];
        preBackupScript = ''
          export PATH=${
            lib.makeBinPath [
              pkgs.sqlite
              pkgs.coreutils
            ]
          }
          mkdir -p /var/backup/mautrix-signal
          sqlite3 /var/lib/mautrix-signal/mautrix-signal.db ".timeout 120000" ".backup '/var/backup/mautrix-signal/mautrix-signal.db'"
          cp /var/lib/mautrix-signal/signal-registration.yaml /var/backup/mautrix-signal/
        '';
      };

      # one-time: paste signal-registration.yaml into #admins via
      # `!admin appservices register` (continuwuity has no file-based registration)
      systemd.services.mautrix-signal = {
        wants = [ "continuwuity.service" ];
        after = [ "continuwuity.service" ];
        # upstream nixpkgs pre-start trips SC2086
        enableStrictShellChecks = false;
      };
    };
}
