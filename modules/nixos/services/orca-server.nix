_: {
  # binds 0.0.0.0 only (no bind flag, no ipv6), so yggdrasil cannot reach it.
  # workstations dial the workspace-relay ssh forward on 127.0.0.1; the phone
  # pairs once over netbird by hand. pairing url: journalctl --user -u orca-server
  flake.modules.homeManager.orcaServer =
    { inputs, pkgs, ... }:
    let
      orca = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.orca;
    in
    {
      home.packages = [ orca ];

      systemd.user.services.orca-server = {
        Unit.Description = "Orca headless runtime";
        Service = {
          ExecStart = "${orca}/bin/orca serve --port 6769 --pairing-address 127.0.0.1";
          WorkingDirectory = "%h";
          # home-manager user units get no PATH; agents (pi, omp, claude) and
          # their tools come from the user and system profiles
          Environment = [
            "PATH=/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
            "ORCA_TELEMETRY_DISABLED=1"
          ];
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
