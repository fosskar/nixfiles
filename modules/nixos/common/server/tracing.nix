{
  flake.modules.nixos.server =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = [
        pkgs.strace
        (lib.lowPrio config.boot.kernelPackages.perf)
      ];
    };
}
