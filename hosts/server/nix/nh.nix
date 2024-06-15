_: {
  environment.variables.FLAKE = "/home/oscar/code/nixfiles";

  programs.nh = {
    enable = true;
    flake = "/home/oscar/code/nixfiles";
    clean = {
      enable = true;
      extraArgs = "--keep 3";
    };
  };
}
