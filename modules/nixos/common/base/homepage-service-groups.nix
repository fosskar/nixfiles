{
  # declared in base (all machines) so any host can author homepage tiles via
  # services.homepage-dashboard.serviceGroups — even hosts that don't run
  # homepage. the homepage host collects them across the fleet and renders them.
  flake.modules.nixos.base =
    { lib, ... }:
    {
      options.services.homepage-dashboard.serviceGroups = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.listOf (lib.types.attrsOf (lib.types.attrsOf lib.types.anything))
        );
        default = { };
        description = "homepage services keyed by group; collected across the fleet and rendered on the homepage host.";
      };
    };
}
