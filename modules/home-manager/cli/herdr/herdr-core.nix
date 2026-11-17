{
  flake.modules.homeManager.herdrCore =
    {
      config,
      inputs,
      options,
      pkgs,
      lib,
      ...
    }:
    let
      herdr-core = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr-core;
      hc = lib.getExe herdr-core;
      jq = lib.getExe pkgs.jq;
      machines = config.programs.herdr-core.machines;

      # pi-subagent-manager agents as hc templates: thinkingLevel and tools.allow
      # become pi flags, the body stays the opening instructions
      templates = pkgs.runCommand "herdr-core-templates" { nativeBuildInputs = [ pkgs.yq-go ]; } ''
        mkdir $out
        for f in ${inputs.pi-subagent-manager}/agents/*.md; do
          name=$(basename "$f" .md)
          head=$(awk 'NR == 1 && /^---$/ { next } /^---$/ { exit } { print }' "$f")
          description=$(printf '%s\n' "$head" | yq -e '.description' | tr '\n' ' ' | sed 's/ *$//')
          thinking=$(printf '%s\n' "$head" | yq -e '.thinkingLevel')
          tools=$(printf '%s\n' "$head" | yq -e '.tools.allow | join(",")')
          {
            echo ---
            echo "description: $description"
            echo "command: pi --thinking $thinking --tools $tools"
            echo ---
            awk 'f == 2 { print; next } /^---$/ { f++ }' "$f"
          } > "$out/$name.md"
        done
      '';
    in
    {
      options.programs.herdr-core.machines = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "workspace" ];
        description = "ssh targets the local core adds as machines of the same name; removing one does not remove it from the core.";
      };

      config = {
        home.packages = [ herdr-core ];

        xdg.configFile = {
          # off by default: show a lost kept program's last screen above the new shell
          "herdr-core/config.toml".text = ''
            restore_screen = true
          '';
          "herdr-core/templates".source = templates;
        };

        llm = lib.optionalAttrs (options.llm or { } ? externalSkills) {
          externalSkills.herdr-core = "${herdr-core}/share/skills/herdr-core/herdr-core/SKILL.md";
        };

        # the core keeps machines in its state with the remote core's id, so
        # nix cannot write machines.json; add the missing ones instead.
        # `machine add` needs ssh to the target, hence a retrying service
        # rather than an activation step.
        systemd.user.services.herdr-core-machines = lib.mkIf (machines != [ ]) {
          Unit.Description = "add herdr-core machines";
          Service = {
            Type = "oneshot";
            Restart = "on-failure";
            RestartSec = 60;
            ExecStart = toString (
              pkgs.writeShellScript "herdr-core-machines" ''
                set -eu
                have=$(${hc} machine ls --json | ${jq} -r '.machines[].name')
                for m in ${lib.escapeShellArgs machines}; do
                  printf '%s\n' "$have" | grep -qxF "$m" || ${hc} machine add "$m" --name "$m"
                done
              ''
            );
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
