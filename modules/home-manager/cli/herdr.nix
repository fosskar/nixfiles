{
  flake.modules.homeManager.herdr =
    { inputs, pkgs, ... }:
    {
      home.packages = [
        inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr
      ];
    };
}
