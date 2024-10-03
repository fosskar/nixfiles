{ config, ... }:
{
  environment.variables.FLAKE = "${config.users.users.simon.home}/code/nixfiles";

  programs.nh = {
    enable = true;
    flake = "${config.users.users.simon.home}/code/nixfiles";
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 3";
    };
  };
}
