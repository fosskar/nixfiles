# custom netbird server module — replaces outdated nixpkgs server modules
{
  mylib,
  ...
}:
{
  disabledModules = [
    "services/networking/netbird/server.nix"
    "services/networking/netbird/management.nix"
    "services/networking/netbird/signal.nix"
  ];

  imports = mylib.scanPaths ./. { };
}
