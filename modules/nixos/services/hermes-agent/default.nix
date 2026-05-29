{
  flake.modules.nixos.hermesAgent =
    {
      config,
      inputs,
      ...
    }:
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      environment.shellAliases.hermes = "sudo -u hermes -H hermes";

      clan.core.vars.generators.hermes-agent = {
        files.envfile = {
          owner = config.services.hermes-agent.user;
          group = config.services.hermes-agent.group;
          secret = true;
        };
        prompts.hass-url = {
          description = "Home Assistant URL for hermes-agent";
          persist = true;
        };
        prompts.hass-token = {
          description = "Home Assistant long-lived access token for hermes-agent";
          type = "hidden";
          persist = true;
        };
        script = ''
          {
            echo "HASS_URL=$(cat "$prompts/hass-url")"
            echo "HASS_TOKEN=$(cat "$prompts/hass-token")"
          } > "$out/envfile"
        '';
      };

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;
        environmentFiles = [ config.clan.core.vars.generators.hermes-agent.files.envfile.path ];

        extraDependencyGroups = [
          "voice" # STT: faster-whisper, sounddevice
          #"edge-tts" # free TTS provider
          "matrix"
        ];

        #documents."SOUL.md" = ./SOUL.md;

        settings = {
          timezone = "Europe/Berlin";

          model = {
            default = "openai-codex/gpt-5.5";
          };

          toolsets = [
            "homeassistant"
          ];
        };

        environment = {
          SIGNAL_ACCOUNT = "+4915251840217";
          SIGNAL_ALLOWED_USERS = "dcca284c-5b24-4eba-8e40-bb9649c1502c";
          SIGNAL_HTTP_URL = "http://127.0.0.1:18081";
        };
      };
    };
}
