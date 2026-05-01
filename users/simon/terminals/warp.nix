{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.custom.warp-terminal
  ];
}
