{
  flake.modules.nixos.tracing =
    {
      lib,
      pkgs,
      ...
    }:
    {
      programs.bcc.enable = !pkgs.stdenv.hostPlatform.isRiscV;
      programs.sysdig.enable = !pkgs.stdenv.hostPlatform.isAarch64 && !pkgs.stdenv.hostPlatform.isRiscV;

      # needed by many bcc/ftrace workflows; import this module only while debugging.
      boot.kernel.sysctl."kernel.ftrace_enabled" = lib.mkForce true;
    };
}
