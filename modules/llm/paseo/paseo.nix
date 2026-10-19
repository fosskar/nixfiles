{ lib, ... }:
let
  # llm-agents only packages paseo-desktop; its share/ also holds the traced
  # daemon and cli closure, with node-pty built against nodejs_22
  paseoFor =
    { inputs, pkgs }:
    let
      desktop = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.paseo-desktop;
      root = "${desktop}/share/paseo-desktop";
      node = lib.getExe pkgs.nodejs_22;
    in
    {
      inherit desktop root node;
      cli = pkgs.writeShellScriptBin "paseo" ''
        export NODE_PATH=${root}/node_modules
        exec ${node} ${root}/packages/cli/dist/index.js "$@"
      '';
    };
in
{
  # no llm.externalSkills: each daemon (the desktop app's and paseo-server)
  # copies its bundled skills into ~/.agents, ~/.claude and ~/.codex at
  # start, selectable in the app, and refuses to write through symlinks
  flake.modules.homeManager.paseoDesktop =
    { inputs, pkgs, ... }:
    let
      paseo = paseoFor { inherit inputs pkgs; };
    in
    {
      home.packages = [
        paseo.desktop
        paseo.cli
      ];
    };

  # listens on 127.0.0.1:6767 (upstream default); the desktop app reaches it
  # through its remote ssh transport as "ssh://workspace". relay stays
  # switchable in the app because no PASEO_RELAY_ENABLED override is set
  flake.modules.homeManager.paseoServer =
    { inputs, pkgs, ... }:
    let
      paseo = paseoFor { inherit inputs pkgs; };
    in
    {
      home.packages = [ paseo.cli ];

      systemd.user.services.paseo-server = {
        Unit.Description = "Paseo daemon";
        Service = {
          ExecStart = "${paseo.node} ${paseo.root}/packages/server/dist/scripts/supervisor-entrypoint.js";
          WorkingDirectory = "%h";
          # home-manager user units get no PATH; agents and their tools come
          # from the user and system profiles
          Environment = [
            "PATH=/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
            "PASEO_NODE_ENV=production"
          ];
          Restart = "on-failure";
          RestartSec = 5;
          # the daemon finishes its own shutdown within 10s of SIGTERM
          TimeoutStopSec = 15;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
