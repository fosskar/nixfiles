_: {
  environment.variables.FLAKE = "/home/simon/code/nixfiles";

  programs.nh = {
    enable = true;
    flake = "/home/simon/code/nixfiles";
    clean = {
      enable = true;
      extraArgs = "--keep 3";
    };
  };
}
