{ pkgs, ... }:
{
  flake.modules.homeManager.ladybird = _: {
    home.packages = [
      pkgs.ladybird
    ];
  };
}
