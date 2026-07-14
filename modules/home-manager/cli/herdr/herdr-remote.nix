# herdr-remote relay: agent dashboard reachable from phone/web/telegram.
# enable on the host whose agents should be monitored; expose via netbird.
{
  flake.modules.homeManager.herdr =
    {
      inputs,
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.herdr.remote;

      # relay runs from a pinned copy, not the runtime plugin checkout: that
      # path is hashed, changes on version bump, and only exists after
      # activation installed the plugin
      relaySrc = pkgs.fetchFromGitHub {
        owner = "dcolinmorgan";
        repo = "herdr-remote";
        rev = "a11605060bbc0ca93eff46fa632dcc84dc11f2d1";
        hash = "sha256-8A7caqpOXTihsYaQh8MS6cxe3NvZ7gL2ZJwdhrltdDs=";
      };
      # whole tree, not the lone script: GET / serves ../web/index.html
      # relative to the script. upstream hardcodes the bind address; patch it
      # to honor HERDR_RELAY_HOST
      relayTree = pkgs.runCommand "herdr-remote-relay" { } ''
        cp -r ${relaySrc} $out
        chmod -R u+w $out
        substituteInPlace $out/relay/herdr_relay.py \
          --replace-fail 'serve(handle_client, "0.0.0.0", WS_PORT' \
                         'serve(handle_client, os.environ.get("HERDR_RELAY_HOST", "0.0.0.0"), WS_PORT'
      '';
      relayPython = pkgs.python3.withPackages (ps: [
        ps.websockets
        ps.zeroconf
      ]);
      # token exported at start, not via Environment=: keeps the secret out of
      # `systemctl show` and the unit file
      relayStart = pkgs.writeShellScript "herdr-relay-start" ''
        ${lib.optionalString (cfg.tokenFile != null) ''
          HERDR_RELAY_TOKEN="$(cat ${cfg.tokenFile})"
          export HERDR_RELAY_TOKEN
        ''}
        exec ${relayPython}/bin/python ${relayTree}/relay/herdr_relay.py
      '';

      herdrBin = lib.getExe inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
    in
    {
      options.programs.herdr.remote = {
        enable = lib.mkEnableOption "herdr-remote relay (agent dashboard for phone/web/telegram)";
        ip = lib.mkOption {
          type = lib.types.str;
          default = "0.0.0.0";
          description = "bind address; keep 0.0.0.0 for netbird exposure";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 8375;
          description = "relay listen port (WebSocket + HTTP POST)";
        };
        tokenFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "file with the shared auth token; null disables auth";
        };
      };

      config.systemd.user.services.herdr-relay = lib.mkIf cfg.enable {
        Unit = {
          Description = "herdr-remote relay (agent dashboard)";
          After = [ "network.target" ];
        };
        Service = {
          Environment = [
            "HERDR_BIN=${herdrBin}"
            "HERDR_RELAY_HOST=${cfg.ip}"
            "HERDR_RELAY_PORT=${toString cfg.port}"
          ];
          ExecStart = "${relayStart}";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
