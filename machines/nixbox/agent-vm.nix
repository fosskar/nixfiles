{ config, self, ... }:
{
  imports = [ self.modules.nixos.agentVm ];

  nixfiles.agentVm = {
    services = [
      self.modules.nixos.hermesAgent
      # the virtiofs mount does not exist yet when hermes' module merges
      # environmentFiles into .env at activation, so hand the file to systemd
      # at start-up instead. hermesAgent itself knows nothing about the vm
      {
        systemd.services = {
          hermes-agent = {
            serviceConfig.EnvironmentFile = "/run/agent-secrets/hermes.env";
            unitConfig.RequiresMountsFor = [ "/run/agent-secrets" ];
          };
          hermes-dashboard = {
            serviceConfig.EnvironmentFile = "/run/agent-secrets/hermes.env";
            unitConfig.RequiresMountsFor = [ "/run/agent-secrets" ];
          };
        };
      }
    ];

    secrets."hermes.env" = config.clan.core.vars.generators.hermes-agent.files.".env".path;
  };

  clan.core.vars.generators.hermes-agent = {
    files.".env".secret = true;
    prompts.matrix-password = {
      description = "matrix password for @hermes:fosskar.de";
      type = "hidden";
      persist = true;
    };
    prompts.matrix-recovery-key = {
      description = "Matrix recovery key for @hermes:fosskar.de";
      type = "hidden";
      persist = true;
    };
    prompts.openrouter-api-key = {
      description = "OpenRouter API key";
      type = "hidden";
      persist = true;
    };
    script = ''
      {
        echo "MATRIX_PASSWORD=$(cat "$prompts/matrix-password")"
        echo "MATRIX_RECOVERY_KEY=$(cat "$prompts/matrix-recovery-key")"
        echo "OPENROUTER_API_KEY=$(cat "$prompts/openrouter-api-key")"
      } > "$out/.env"
    '';
  };
}
