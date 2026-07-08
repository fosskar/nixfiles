{
  flake.modules.nixos.opencrow =
    {
      flake-self,
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      micsSkills = inputs.mics-skills.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [ inputs.opencrow.nixosModules.default ];

      clan.core.vars.generators.opencrow = {
        files.".env" = { };
        prompts.matrix-password = {
          description = "Matrix account password for the opencrow bot (@opencrow:fosskar.de)";
          type = "hidden";
          persist = true;
        };
        script = ''
          echo "OPENCROW_MATRIX_PASSWORD=$(cat "$prompts/matrix-password")" > "$out/.env"
        '';
      };

      services.opencrow = {
        enable = true;
        piPackage = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp;

        environmentFiles = [ config.clan.core.vars.generators.opencrow.files.".env".path ];

        environment = {
          OPENCROW_BACKEND = "matrix";
          OPENCROW_MATRIX_HOMESERVER = "https://matrix.${flake-self.domains.public}";
          OPENCROW_MATRIX_USER_ID = "@opencrow:fosskar.de";
          OPENCROW_ALLOWED_USERS = "@fosskar:fosskar.de";
          OPENCROW_SOUL_FILE = "${./SOUL.md}";

          OPENCROW_HEARTBEAT_INTERVAL = "30m";
          OPENCROW_PI_IDLE_TIMEOUT = "6h";
          OPENCROW_PI_PROVIDER = "llama.cpp";
          OPENCROW_PI_MODEL = "qwen3_6-35b-a3b-mtp";
          LLAMA_CPP_BASE_URL = "http://127.0.0.1:18080";
          SEARXNG_ENDPOINT = "http://127.0.0.1:8888";
          TZ = "Europe/Berlin";
        };

        extensions = {
          memory = true;
          reminders = true;
        };

        skills = {
          web = "${config.services.opencrow.package}/share/opencrow/skills/web";
          db = "${micsSkills.db-cli}/share/skills/db-cli";
          weather = "${micsSkills.weather-cli}/share/skills/weather-cli";
          context7 = "${micsSkills.context7-cli}/share/skills/context7-cli";
          datetime = "${flake-self}/modules/home-manager/llm/skills/datetime";
        };

        extraPackages = [
          micsSkills.db-cli
          micsSkills.weather-cli
          micsSkills.context7-cli
        ]
        ++ (with pkgs; [
          curl
          jq
          ripgrep
          fd
          git
          python3
        ]);
      };
    };
}
