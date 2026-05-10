{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  skillTargetDirs =
    lib.optionals (config.home.activation ? piSettings) [ ".pi/agent/skills" ]
    ++ lib.optionals (config.programs.claude-code.enable or false) [ ".claude/skills" ]
    ++ lib.optionals (config.programs.codex.enable or false) [ ".codex/skills" ]
    ++ lib.optionals (config.programs.gemini-cli.enable or false) [ ".gemini/skills" ]
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

in
{
  imports = [ inputs.mics-skills.homeModules.default ];

  home.file = ownSkillEntries;

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
    ];
  };
}
