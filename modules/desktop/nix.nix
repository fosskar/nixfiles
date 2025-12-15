{
  lib,
  config,
  ...
}:
let
  hasAccessTokens = config.sops.secrets ? "nix-access-tokens";
in
{
  assertions = [
    {
      assertion = config.programs.nh.enable -> config.programs.nh.flake != null;
      message = "programs.nh.flake must be set when nh is enabled (e.g. \${config.users.users.<user>.home}/code/nixfiles)";
    }
  ];

  # better desktop responsiveness during builds
  nix.daemonCPUSchedPolicy = "idle";

  # include access tokens for private repos if secret exists
  nix.extraOptions = lib.mkIf hasAccessTokens ''
    !include ${config.sops.secrets."nix-access-tokens".path}
  '';

  # nh - nix helper for desktop users
  # flake path set per-machine via programs.nh.flake or NH_FLAKE env var
  programs.nh = {
    enable = lib.mkDefault true;
    clean = {
      enable = lib.mkDefault true;
      extraArgs = lib.mkDefault "--keep 5 --keep-since 3d";
    };
  };
}
