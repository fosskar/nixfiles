_: {
  flake.modules.nixos.mcp =
    { self, ... }:
    {
      imports = [
        self.modules.nixos.fencr
        self.modules.nixos.mcpCalendar
        self.modules.nixos.mcpGrafana
      ];
      fencr.mcpGateway = {
        enable = true;
        approvalMode = "client";
      };
      preservation.preserveAt."/persist".directories = [ "/var/lib/fencr-mcp" ];
    };
}
