_: {
  flake.modules.nixos.mcp =
    { self, ... }:
    {
      imports = [
        self.modules.nixos.fencr
        self.modules.nixos.mcpOpencloud
        self.modules.nixos.mcpGrafana
      ];
      fencr.mcpGateway.enable = true;
    };
}
