_: {
  flake.modules.homeManager.llm =
    { pkgs, inputs, ... }:
    {
      programs.git.ignores = [ ".opencode/" ];

      programs.opencode = {
        enable = true;
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
        context = ../AGENTS.md;
      };
    };
}
