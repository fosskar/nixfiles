_: {
  environment.variables.FLAKE = "/home/simon/nixfiles";

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep 3";
    flake = "/home/simon/nixfiles";
  };
}
