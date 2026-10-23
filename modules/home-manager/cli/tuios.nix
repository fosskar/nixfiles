{
  flake.modules.homeManager.tuios =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.tuios ];
    };
}
