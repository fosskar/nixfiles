{
  flake.modules.nixos.agentDesktop =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.local.agent-desktop ];
    };
}
