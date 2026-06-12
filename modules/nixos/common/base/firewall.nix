{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      networking = {
        # firewall enabled by default upstream
        firewall.logRefusedConnections = lib.mkDefault false;
        nftables.enable = lib.mkDefault true;
      };
    };
}
