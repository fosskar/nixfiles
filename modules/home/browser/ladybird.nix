_: {
  flake.modules.homeManager.ladybird =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ladybird ];
    };
}
