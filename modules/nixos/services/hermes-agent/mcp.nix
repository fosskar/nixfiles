_: {
  # hermes' side of the mcp gateway: stage the gateway token into the vm,
  # point the agent at the gateway, and open the host<->vm path. this glue is
  # owned by the hermes feature — mcpGateway itself knows nothing about agent
  # vms. import on a host that runs both the gateway and the hermes vm.
  flake.modules.nixos.hermesAgentMcp =
    { config, ... }:
    let
      inherit (config.services.mcpGateway) port;
      vm = config.nixfiles.agentVms.hermes;
    in
    {
      nixfiles.agentVms.hermes = {
        secrets."mcp-gateway.env" = config.clan.core.vars.generators.mcp-gateway.files."token.env".path;
        services = [
          (
            { lib, ... }:
            {
              services.hermes-agent.settings.mcp_servers.nixfiles = {
                url = "http://${vm.hostIp}:${toString port}/mcp/";
                headers.Authorization = "Bearer \${MCP_GATEWAY_TOKEN}";
                elicitation = {
                  enabled = true;
                  timeout = 300;
                };
              };

              systemd.services.hermes-agent.serviceConfig.EnvironmentFile = lib.mkAfter [
                "/run/agent-secrets/mcp-gateway.env"
              ];
              systemd.services.hermes-dashboard.serviceConfig.EnvironmentFile = lib.mkAfter [
                "/run/agent-secrets/mcp-gateway.env"
              ];
            }
          )
        ];
      };

      systemd.services.mcp-gateway.serviceConfig.IPAddressAllow = [ "${vm.ip}/32" ];

      networking.firewall.interfaces.${vm.bridge}.allowedTCPPorts = [ port ];
    };
}
