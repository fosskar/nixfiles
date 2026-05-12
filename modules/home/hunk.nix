{
  flake.modules.homeManager.hunk =
    { inputs, ... }:
    {
      imports = [
        inputs.hunk.homeManagerModules.default
      ];

      programs = {
        hunk = {
          enable = true;
          enableGitIntegration = true;
          settings = {
            theme = "graphite";
            mode = "auto";
            vcs = "jj";
            line_numbers = true;
            agent_notes = true;
            wrap_lines = true;
          };
        };

        jujutsu.settings.ui = {
          pager = [
            "hunk"
            "pager"
          ];
          diff-formatter = ":git";
        };
      };
    };
}
