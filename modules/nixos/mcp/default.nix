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
      # the mode lives on the persisted directory; a bare entry would put
      # 0755 there and out-rank the module's tmpfiles rule
      preservation.preserveAt."/persist".directories = [
        {
          directory = "/var/lib/fencr-mcp";
          mode = "0700";
        }
      ];
    };
}
