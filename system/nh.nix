{
  config,
  pkgs,
  ...
}: {
  environment.variables.FLAKE = "/home/simon/nixfiles";

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/simon/nixfiles";
  };
}
