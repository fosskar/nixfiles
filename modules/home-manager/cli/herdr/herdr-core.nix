{
  flake.modules.homeManager.herdrCore =
    {
      options,
      pkgs,
      lib,
      ...
    }:
    {
      config = {
        home.packages = [ pkgs.local.herdr-core ];

        llm = lib.optionalAttrs (options.llm or { } ? externalSkills) {
          externalSkills.herdr-core = "${pkgs.local.herdr-core.src}/skills/herdr-core/SKILL.md";
        };
      };
    };
}
