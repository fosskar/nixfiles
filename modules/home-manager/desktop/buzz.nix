{
  flake.modules.homeManager.buzz =
    { inputs, pkgs, ... }:
    {
      home.packages = [
        inputs.buzz-flake.packages.${pkgs.stdenv.hostPlatform.system}.buzz-desktop
      ];
    };
}
