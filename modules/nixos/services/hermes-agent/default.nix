{
  flake.modules.nixos.hermesAgent =
    {
      flake-self,
      config,
      inputs,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      environment.shellAliases.hermes = "sudo -u simon -H hermes";

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
        prompts.matrix-access-token = {
          description = "Matrix access token for hermes-agent";
          type = "hidden";
          persist = true;
        };
        prompts.matrix-recovery-key = {
          description = "Matrix recovery key (Security Key) for hermes-agent cross-signing";
          type = "hidden";
          persist = true;
        };
        script = ''
          {
            echo "HASS_URL=$(cat "$prompts/hass-url")"
            echo "HASS_TOKEN=$(cat "$prompts/hass-token")"
            echo "OPENCODE_GO_API_KEY=$(cat "$prompts/opencode-api-key")"
            echo "MATRIX_ACCESS_TOKEN=$(cat "$prompts/matrix-access-token")"
            echo "MATRIX_RECOVERY_KEY=$(cat "$prompts/matrix-recovery-key")"
          } > "$out/.env"
        '';
      };

      nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;
        createUser = false;
        user = "simon";
        group = "users";
        stateDir = "/home/simon";
        environmentFiles = [ config.clan.core.vars.generators.hermes-agent.files.".env".path ];
        extraPackages = [
          pkgs.agent-browser
          pkgs.chromium
          pkgs.curl
          pkgs.olm
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

          terminal.cwd = "/home/simon/workspace";

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

          SEARXNG_URL = "https://search.${flake-self.domains.local}/";

          MATRIX_HOMESERVER = "https://matrix.org";
          MATRIX_ALLOWED_USERS = "@fosscar:matrix.org";
          #MATRIX_ENCRYPTION = "true";
        };
      };
    };
}
