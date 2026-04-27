{
  flake.modules.nixos.agentDesktop =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.custom.agent-desktop ];
    };
}
