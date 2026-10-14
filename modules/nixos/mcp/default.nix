_: {
  flake.modules.nixos.mcp =
    { self, ... }:
    {
      imports = [
        self.modules.nixos.fencr
        self.modules.nixos.mcpCalendar
        self.modules.nixos.mcpGrafana
        self.modules.nixos.mcpLaya
      ];
      fencr.mcpGateway.enable = true;
    };
}
