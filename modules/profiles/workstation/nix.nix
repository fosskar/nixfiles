{
  lib,
  config,
  ...
}:
let
  hasAccessTokens = config.sops.secrets ? "nix-access-tokens";
in
{
  # srvos.desktop sets: daemonCPUSchedPolicy = "idle"

  assertions = [
    {
      assertion = config.programs.nh.enable -> config.programs.nh.flake != null;
      message = "programs.nh.flake must be set when nh is enabled";
    }
  ];

  # include access tokens for private repos if secret exists
  nix.extraOptions = lib.mkIf hasAccessTokens ''
    !include ${config.sops.secrets."nix-access-tokens".path}
  '';

  # allow running unpatched binaries (editor LSPs, etc.)
  programs.nix-ld.enable = true;

  # nh - nix helper for desktop users
  programs.nh = {
    enable = lib.mkDefault true;
    clean = {
      enable = lib.mkDefault true;
      extraArgs = lib.mkDefault "--keep 5 --keep-since 3d";
    };
  };
}
