{
  flake.modules.homeManager.hunk =
    {
      lib,
      options,
      pkgs,
      ...
    }:
    {
      home.packages = [ pkgs.hunk ];

      llm = lib.optionalAttrs (options.llm or { } ? externalSkills) {
        externalSkills.hunk-review = "${pkgs.hunk}/share/skills/hunk/hunk-review/SKILL.md";
      };
    };
}
