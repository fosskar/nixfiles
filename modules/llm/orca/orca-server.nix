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
      llmPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      inherit (llmPackages) orca;
      pairingAddress = "${osConfig.networking.hostName}.nb.${self.domains.public}";
    in
    {
      home.packages = [
        orca
        llmPackages.agent-browser
      ];

      # stubs from stablyai/orca v1.4.224 skills/; they load the version-matched
      # guide from the orca binary. computer-use is left out: on a headless
      # server it would drive nixworker, not the client's desktop
      llm.externalSkills = {
        orchestration = ./skills/orchestration/SKILL.md;
        orca-cli = ./skills/orca-cli/SKILL.md;
      };

      # orca serve starts a private Xvfb on :99 for its browser panes and leaks
      # DISPLAY into terminals; with it set, pi copies to that invisible X
      # clipboard instead of using OSC 52. orca also gives each worktree its
      # own fish history (fish_history=orca_<id>); switch back to the shared
      # one, session "fish" (file fish_history; "default" is a new empty session)
      programs.fish.interactiveShellInit = ''
        if test "$TERM_PROGRAM" = Orca; and test "$DISPLAY" = :99
          set -e DISPLAY
        end
        if string match -q 'orca_*' -- "$fish_history"
          set -gx fish_history fish
        end
      '';

      # every orca worktree and jj workspace is a new path, which direnv would
      # make me allow again; trusts any .envrc under these prefixes
      programs.direnv.config.whitelist.prefix = [
        "~/Projects"
        "~/orca/workspaces"
      ];

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
            # orca's terminal never answers fish's primary device attribute
            # query, so every new shell would stall 10s and print a warning
            "fish_features=no-query-term"
          ];
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
