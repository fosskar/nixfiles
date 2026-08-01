_: {
  flake.modules.nixos.mcp =
    { self, ... }:
    {
      imports = [
        self.modules.nixos.mcpGateway
        self.modules.nixos.mcpCalendar
      ];
    };
}
