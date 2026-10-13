_: {
  flake.modules.homeManager.orcaDesktop =
    { inputs, pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.orca ];
    };
}
