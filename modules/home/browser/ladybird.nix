_: {
  flake.modules.homeManager.ladybird =
    { pkgs, ... }:
    {
      home.packages = [
        # Disabled while nixpkgs ladybird fails to build with mismatched ICU/libjxl deps.
        # pkgs.ladybird
      ];
    };
}
