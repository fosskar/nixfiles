_: {
  # binds 0.0.0.0 only (no bind flag, no ipv6), so the ipv6-only clan networks
  # cannot reach it; clients dial the netbird ipv4 address. the port stays out
  # of the nixos firewall, which never sees netbird traffic.
  # pairing url: journalctl --user -u orca-server
  flake.modules.homeManager.orcaServer =
    {
      inputs,
      osConfig,
      pkgs,
      self,
      ...
    }:
    let
      orca = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.orca;
      pairingAddress = "${osConfig.networking.hostName}.nb.${self.domains.public}";
    in
    {
      home.packages = [ orca ];

      systemd.user.services.orca-server = {
        Unit.Description = "Orca headless runtime";
        Service = {
          ExecStart = "${orca}/bin/orca serve --port 6768 --pairing-address ${pairingAddress}";
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
