_: {
  flake.modules.homeManager.llm =
    {
      config,
      osConfig,
      inputs,
      pkgs,
      lib,
      ...
    }:
    let

      skillTargetDirs =
        lib.optionals (config.programs.pi-coding-agent.enable or false) [ ".pi/agent/skills" ]
        ++ lib.optionals (config.programs.claude-code.enable or false) [ ".claude/skills" ]
        ++ lib.optionals (config.programs.codex.enable or false) [ ".codex/skills" ]
        ++ lib.optionals (config.programs.opencode.enable or false) [ ".config/opencode/skills" ];

      ownSkillNames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./.)
      );
      # skills shipped by upstream flake inputs; skill name -> SKILL.md source
      externalSkills = {
        herdr = "${inputs.herdr}/SKILL.md";
        hunk-review = "${pkgs.hunk}/skills/hunk-review/SKILL.md";
      };
      skillEntries = lib.listToAttrs (
        lib.concatMap (
          dir:
          map (name: {
            name = "${dir}/${name}";
            value.source = ./${name};
          }) ownSkillNames
          ++ lib.mapAttrsToList (name: source: {
            name = "${dir}/${name}/SKILL.md";
            value.source = source;
          }) externalSkills
        ) skillTargetDirs
      );

    in
    {
      imports = [ inputs.mics-skills.homeModules.default ];

      home.file = skillEntries;

      xdg.configFile."kagi/config.json".text = builtins.toJSON {
        password_command = "cat ${osConfig.clan.core.vars.generators.kagi.files."session-link".path}";
        timeout = 30;
        max_retries = 5;
      };

      programs.mics-skills = {
        enable = true;
        package = inputs.mics-skills.packages.${pkgs.stdenv.hostPlatform.system};
        skillDirs = skillTargetDirs;
        skills = [
          "calendar-cli"
          "context7-cli"
          "db-cli"
          "gmaps-cli"
          "kagi-search"
        ];
      };
    };
}
