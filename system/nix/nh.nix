_: {
  environment.variables.FLAKE = "${builtins.getEnv "HOME"}/nixfiles";

  programs.nh = {
    enable = true;
    flake = "${builtins.getEnv "HOME"}/nixfiles";
    clean = {
      enable = true;
      extraArgs = "--keep 3";
    };
  };
}
