_: {
  flake.modules.homeManager.llm =
    {
      lib,
      pkgs,
      inputs,
      ...
    }:
    {
      programs.amp = {
        enable = lib.mkDefault false;
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.amp;
      };
    };
}
