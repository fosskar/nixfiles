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
  # installs its bundled skills into ~/.agents and ~/.claude when selected in
  # the app, refreshes them at start, and refuses to write through symlinks
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

      # main.js sets the wayland app_id to "Paseo"; the package only ships
      # paseo-desktop.desktop, so docks and notifications find no icon
      xdg.desktopEntries.Paseo = {
        name = "Paseo";
        exec = "paseo-desktop";
        icon = "paseo-desktop";
        noDisplay = true;
        settings.StartupWMClass = "Paseo";
      };
    };

  flake.modules.nixos.paseoServer = {
    clan.core.vars.generators.paseo-server = {
      files."paseo.env" = {
        owner = "simon";
        group = "users";
      };
      prompts.password = {
        type = "hidden";
        persist = true;
        description = "password for direct connections to the paseo daemon";
      };
      script = ''
        printf 'PASEO_PASSWORD=%s\n' "$(cat "$prompts/password")" > "$out/paseo.env"
      '';
    };
  };

  # binds 0.0.0.0:6767 for direct clients over the netbird mesh; the port
  # stays out of the nixos firewall, which never sees netbird traffic. the
  # password from nixos.paseoServer gates every direct client, loopback and
  # ssh tunnels included; relay clients are admitted on the pairing key
  # alone. relay stays switchable in the app because no PASEO_RELAY_ENABLED
  # override is set
  flake.modules.homeManager.paseoServer =
    {
      inputs,
      osConfig,
      pkgs,
      self,
      ...
    }:
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
            "PASEO_LISTEN=0.0.0.0:6767"
            # literal ips pass the host check by default; names must be listed
            "PASEO_HOSTNAMES=${osConfig.networking.hostName}.nb.${self.domains.public}"
            # agents run without a shell, so the fish shellInit of workspaceHost never sets these
            "SSH_AUTH_SOCK=%t/ssh-agent.sock"
            "BROWSER=remote-open"
          ];
          EnvironmentFile = osConfig.clan.core.vars.generators.paseo-server.files."paseo.env".path;
          Restart = "on-failure";
          RestartSec = 5;
          # the daemon finishes its own shutdown within 10s of SIGTERM
          TimeoutStopSec = 15;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
