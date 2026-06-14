_: {
  flake.modules.homeManager.llm =
    { pkgs, inputs, ... }:
    {
      home.packages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.amp
      ];
    };
}
