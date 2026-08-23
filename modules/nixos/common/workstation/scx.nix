{
  flake.modules.nixos.workstation =
    {
      lib,
      pkgs,
      ...
    }:
    {
      services.scx = {
        enable = true;
        package = pkgs.scx.rustscheds;
        # scx_lavd stalls on both workstations: rcu cpu stall on lpt-titan, and
        # on desktop core compaction collapsed the primary domain to a single
        # cpu, tripping the watchdog every ~48s under a fork-heavy workload
        scheduler = lib.mkDefault "scx_bpfland";
      };
    };
}
