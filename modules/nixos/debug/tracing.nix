{
  flake.modules.nixos.tracing =
    {
      pkgs,
      ...
    }:
    {
      programs.bcc.enable = !pkgs.stdenv.hostPlatform.isRiscV;
      programs.sysdig.enable = !pkgs.stdenv.hostPlatform.isAarch64 && !pkgs.stdenv.hostPlatform.isRiscV;
    };
}
