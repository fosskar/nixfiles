{
  flake.modules.homeManager.herdrCore =
    {
      config,
      options,
      pkgs,
      lib,
      ...
    }:
    let
      hc = lib.getExe pkgs.local.herdr-core;
      jq = lib.getExe pkgs.jq;
      machines = config.programs.herdr-core.machines;
    in
    {
      options.programs.herdr-core.machines = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "workspace" ];
        description = "ssh targets the local core adds as machines of the same name; removing one does not remove it from the core.";
      };

      config = {
        home.packages = [ pkgs.local.herdr-core ];

        llm = lib.optionalAttrs (options.llm or { } ? externalSkills) {
          externalSkills.herdr-core = "${pkgs.local.herdr-core.src}/skills/herdr-core/SKILL.md";
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
