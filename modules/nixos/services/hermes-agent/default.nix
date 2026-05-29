{
  flake.modules.nixos.hermesAgent =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      environment.shellAliases.hermes = "sudo -u hermes -H hermes";

      clan.core.vars.generators.hermes-agent = {
        files.".env" = {
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
        prompts.opencode-api-key = {
          description = "OpenCode API key";
          type = "hidden";
          persist = true;
        };
        script = ''
          {
            echo "HASS_URL=$(cat "$prompts/hass-url")"
            echo "HASS_TOKEN=$(cat "$prompts/hass-token")"
            echo "OPENCODE_GO_API_KEY=$(cat "$prompts/opencode-api-key")"
          } > "$out/.env"
        '';
      };

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;
        environmentFiles = [ config.clan.core.vars.generators.hermes-agent.files.".env".path ];
        extraPackages = [
          pkgs.agent-browser
          pkgs.chromium
          pkgs.curl
        ];

        extraDependencyGroups = [
          "voice"
          "matrix"
        ];

        #documents."SOUL.md" = ./SOUL.md;

        settings = {
          timezone = "Europe/Berlin";

          model = {
            default = "deepseek-v4-flash";
            provider = "opencode-go";
          };

          toolsets = [
            "homeassistant"
          ];

          plugins.enabled = [
            "disk-cleanup"
          ];

          stt = {
            provider = "local";
            # local faster-whisper models: tiny, base, small, medium, large-v3.
            local.model = "small";
          };

          tts = {
            provider = "nixbox-piper";
            providers.nixbox-piper = {
              type = "command";
              command = "curl -fsS -H 'Content-Type: text/plain' --data-binary @{input_path} https://piper.nx3.eu/api/text-to-speech -o {output_path}";
              output_format = "wav";
            };
          };
        };

        environment = {
          SIGNAL_ACCOUNT = "+4915251840217";
          SIGNAL_ALLOWED_USERS = "dcca284c-5b24-4eba-8e40-bb9649c1502c";
          SIGNAL_HTTP_URL = "http://127.0.0.1:18081";

          SEARXNG_URL = "https://search.${config.domains.local}/";
        };
      };
    };
}
