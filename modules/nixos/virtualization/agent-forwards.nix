_: {
  # microvms and containers derive their forward ports from one instance id
  # space, so uniqueness has to hold across both namespaces. each sandbox
  # contributes the endpoints it claims rather than reading the other's
  # options, which need not be declared.
  # `key` keeps the option declared once when a host imports both sandboxes
  flake.modules.nixos.agentForwards = {
    key = "nixfiles/agent-forwards";
    imports = [
      (
        { config, lib, ... }:
        {
          options.nixfiles.agentForwardEndpoints = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            internal = true;
            description = "host endpoints claimed by agent sandbox forwards, as address:port.";
          };

          config.assertions = [
            {
              assertion = lib.allUnique config.nixfiles.agentForwardEndpoints;
              message = "agent sandbox forwards: host listen endpoints must be unique across microvms and containers.";
            }
          ];
        }
      )
    ];
  };
}
