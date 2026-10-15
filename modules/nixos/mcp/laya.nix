_: {
  flake.modules.nixos.mcpLaya =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    {
      # fencr runs it once per sandbox session, on a socket only its gateway reaches
      fencr.mcpGateway.servers.laya.command = [ (lib.getExe pkgs.local.laya-mcp) ];

      systemd.services."fencr-mcp-backend-laya@" = {
        environment.LAYA_URL = "https://laya.${flake-self.domains.local}";
        serviceConfig = {
          IPAddressAllow = [
            "127.0.0.53/32"
            "${flake-self.hosts.nixbox.lan}/32"
            "${builtins.head config.networking.nameservers}/32"
          ];
          IPAddressDeny = "any";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
        };
      };
    };
}
