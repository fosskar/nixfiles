_: {
  flake.modules.homeManager.brave =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.custom.brave-origin ];
    };
}
