_: {
  # session link for the kagi-search skill below; hosts whose users import
  # homeManager.llm import this
  flake.modules.nixos.llm = {
    clan.core.vars.generators.kagi = {
      share = true;
      files."session-link".owner = "simon";
      prompts."session-link" = {
        type = "hidden";
        persist = true;
        description = "kagi session link";
      };
    };
  };

  flake.modules.homeManager.llm =
    {
      config,
      osConfig,
      inputs,
      pkgs,
      lib,
      self,
      ...
    }:
    let

      skillTargetDirs =
        lib.optionals (config.programs.pi-coding-agent.enable or false) [ ".pi/agent/skills" ]
        ++ lib.optionals (config.programs.claude-code.enable or false) [ ".claude/skills" ]
        ++ lib.optionals (config.programs.codex.enable or false) [ ".codex/skills" ]
        ++ lib.optionals (config.programs.opencode.enable or false) [ ".config/opencode/skills" ];

      ownSkills = self.llm.skills;
      piSkills = removeAttrs ownSkills inputs.pi-pack.lib.skills;
      externalSkills = config.llm.externalSkills;
      skillEntries = lib.listToAttrs (
        lib.concatMap (
          dir:
          lib.mapAttrsToList (name: source: {
            name = "${dir}/${name}";
            value.source = source;
          }) (if dir == ".pi/agent/skills" then piSkills else ownSkills)
          ++ lib.mapAttrsToList (name: source: {
            name = "${dir}/${name}/SKILL.md";
            value.source = source;
          }) externalSkills
        ) skillTargetDirs
      );

    in
    {
      imports = [ inputs.mics-skills.homeModules.default ];

      options.llm.externalSkills = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = { };
        description = "skills shipped by upstream packages, contributed by the feature that installs the tool; skill name -> SKILL.md source";
      };

      config = {
        # nixbot-cli lives in the devshell, so no home-manager feature owns its skill
        llm.externalSkills.nixbot-cli = "${
          inputs.nixbot.packages.${pkgs.stdenv.hostPlatform.system}.nixbot-cli
        }/share/skills/nixbot-cli/SKILL.md";

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
            "queue"
          ];
        };
      };
    };
}
