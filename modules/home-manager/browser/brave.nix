_: {
  flake.modules.homeManager.brave =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.local.brave-origin ];
    };
}
