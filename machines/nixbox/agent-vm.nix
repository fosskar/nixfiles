{ config, self, ... }:
{
  imports = [ self.modules.nixos.agentVm ];

  nixfiles.agentVm = {
    allowedTCPDestinations = [
      {
        address = "192.168.10.50";
        port = 8123;
      }
    ];

    services = [
      self.modules.nixos.hermesAgent
      self.modules.nixos.signalCli
      # the virtiofs mount does not exist yet when hermes' module merges
      # environmentFiles into .env at activation, so hand the file to systemd
      # at start-up instead. hermesAgent itself knows nothing about the vm
      {
        systemd.services = {
          hermes-agent = {
            environment.HASS_URL = "http://homeassistant.lan:8123";
            serviceConfig.EnvironmentFile = "/run/agent-secrets/hermes.env";
            unitConfig.RequiresMountsFor = [ "/run/agent-secrets" ];
          };
          hermes-dashboard = {
            environment.HASS_URL = "http://homeassistant.lan:8123";
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
    prompts.home-assistant-token = {
      description = "Home Assistant long-lived access token for Hermes";
      type = "hidden";
      persist = true;
    };
    prompts.signal-account-number = {
      description = "Signal account phone number in E.164 format";
      type = "hidden";
      persist = true;
    };
    script = ''
      {
        echo "MATRIX_PASSWORD=$(cat "$prompts/matrix-password")"
        echo "MATRIX_RECOVERY_KEY=$(cat "$prompts/matrix-recovery-key")"
        echo "OPENROUTER_API_KEY=$(cat "$prompts/openrouter-api-key")"
        echo "HASS_TOKEN=$(cat "$prompts/home-assistant-token")"
        echo "SIGNAL_ACCOUNT=$(cat "$prompts/signal-account-number")"
        echo "SIGNAL_ALLOWED_USERS=$(cat "$prompts/signal-account-number")"
      } > "$out/.env"
    '';
  };
}
