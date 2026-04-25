{
  flake.modules.nixos.server =
    {
      lib,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = [
        pkgs.strace
        (lib.lowPrio pkgs.perf)
      ];
    };
}
