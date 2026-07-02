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
      ownSkillEntries = lib.listToAttrs (
        lib.concatMap (
          name:
          map (dir: {
            name = "${dir}/${name}";
            value.source = ./${name};
          }) skillTargetDirs
        ) ownSkillNames
      );

      mattpocockSkillsSrc = pkgs.fetchFromGitHub {
        owner = "mattpocock";
        repo = "skills";
        rev = "7a83a3a682adf699f24dbc06613de87f4e52a0a0";
        hash = "sha256-NSMNCO6O1/a1oMTAtmtJRERElwUaBRLgpOUXW05qQAQ=";
      };
      mattpocockSkills = [
        "engineering/code-review"
        "engineering/improve-codebase-architecture"
        "engineering/resolving-merge-conflicts"
        "engineering/tdd"
        "productivity/grilling"
        "productivity/handoff"
        "productivity/teach"
        "productivity/writing-great-skills"
      ];
      mattpocockSkillEntries = lib.listToAttrs (
        lib.concatMap (
          skill:
          map (dir: {
            name = "${dir}/${baseNameOf skill}";
            value.source = "${mattpocockSkillsSrc}/skills/${skill}";
          }) skillTargetDirs
        ) mattpocockSkills
      );

    in
    {
      imports = [ inputs.mics-skills.homeModules.default ];

      home.file = ownSkillEntries // mattpocockSkillEntries;

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
          "buildbot-pr-check"
          "calendar-cli"
          "context7-cli"
          "db-cli"
          "gmaps-cli"
          "kagi-search"
        ];
      };
    };
}
