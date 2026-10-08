_: {
  flake.modules.nixos.mcpLaya =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      llamaCpp = config.services.llama-cpp.settings;
    in
    {
      config = lib.mkIf config.services.llama-cpp.enable {
        # fencr runs it once per sandbox session, on a socket only its gateway reaches
        fencr.mcpGateway.servers.laya.command = [ (lib.getExe pkgs.local.laya-mcp) ];

        systemd.services."fencr-mcp-backend-laya@" = {
          after = [ "llama-cpp.service" ];
          wants = [ "llama-cpp.service" ];
          environment.LAYA_URL = "http://${llamaCpp.host}:${toString llamaCpp.port}";
          serviceConfig = {
            IPAddressAllow = [ "${llamaCpp.host}/32" ];
            IPAddressDeny = "any";
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_UNIX"
            ];
          };
        };
      };
    };
}
