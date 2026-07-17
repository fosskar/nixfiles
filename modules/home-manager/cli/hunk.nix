{
  flake.modules.homeManager.hunk =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.hunk ];
    };
}
