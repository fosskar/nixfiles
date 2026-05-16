# netbird server stack is contributed by server.nix, dashboard.nix, and proxy.nix.
{
  flake.modules.nixos.netbirdServerStack.disabledModules = [
    "services/networking/netbird/server.nix"
    "services/networking/netbird/management.nix"
    "services/networking/netbird/signal.nix"
  ];
}
