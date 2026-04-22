# netbird composite: disables old nixpkgs modules + aggregates sub-modules
{ config, ... }:
{
  flake.modules.nixos.netbird = {
    imports = with config.flake.modules.nixos; [
      netbirdDashboard
      netbirdPersistence
      netbirdProxy
      netbirdServer
    ];
    disabledModules = [
      "services/networking/netbird/server.nix"
      "services/networking/netbird/management.nix"
      "services/networking/netbird/signal.nix"
    ];
  };
}
