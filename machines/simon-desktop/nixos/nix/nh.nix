_: {
  environment.variables.NH_FLAKE = "/home/simon/code/nixfiles";

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 5 --keep-since 3d";
    };
  };
}
