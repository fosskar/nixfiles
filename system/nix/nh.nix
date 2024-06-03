_: {
  environment.variables.FLAKE = "/home/simon/nixfiles";

  programs.nh = {
    enable = true;
    flake = "/home/simon/nixfiles";
    clean = {
      enable = true;
      extraArgs = "--keep 3";
    };
  };
}
