{
  flake.modules.nixos.opencrow =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      localRelayUrl = "ws://127.0.0.1:${toString config.services.strfry.settings.relay.port}";
      paperlessHost = "docs.${config.domains.local}";
      micsSkills = inputs.mics-skills.packages.${pkgs.stdenv.hostPlatform.system};

      kagiConfig = pkgs.writeText "kagi-config.json" (
        builtins.toJSON {
          password_command = "cat /run/credentials/opencrow.service/kagi-session-link";
          timeout = 30;
          max_retries = 5;
        }
      );

      commonInstance = {
        enable = true;

        package = inputs.opencrow.packages.${pkgs.stdenv.hostPlatform.system}.opencrow;
        piPackage = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

        skills = {
          web = "${config.services.opencrow.package}/share/opencrow/skills/web";
          osm = ./skills/osm;
          paperless = ./skills/paperless;
          calendar-cli = "${micsSkills.calendar-cli}/share/skills/calendar-cli";
          db-cli = "${micsSkills.db-cli}/share/skills/db-cli";
          gmaps-cli = "${micsSkills.gmaps-cli}/share/skills/gmaps-cli";
          tasker-cli = "${micsSkills.tasker-cli}/share/skills/tasker-cli";
          kagi-search = "${micsSkills.kagi-search}/share/skills/kagi-search";
        };

        extensions = {
          memory = inputs.opencrow.packages.${pkgs.stdenv.hostPlatform.system}.extension-memory;
          reminders = inputs.opencrow.packages.${pkgs.stdenv.hostPlatform.system}.extension-reminders;
        };

        credentialFiles = {
          "paperless-api-token" = config.clan.core.vars.generators.opencrow-paperless.files.api-token.path;
          "kagi-session-link" = config.clan.core.vars.generators.opencrow-kagi.files.session-link.path;
        };

        environment = {
          TZ = "Europe/Berlin";

          PAPERLESS_URL = "https://${paperlessHost}";

          OPENCROW_PI_PROVIDER = "llama-cpp";
          OPENCROW_PI_MODEL = "qwen3.6-35b-a3b";
        };

        piModels = {
          providers.llama-cpp = {
            baseUrl = "https://llama-cpp.${config.domains.local}/v1";
            api = "openai-completions";
            apiKey = "dummy";
            models = [ { id = "qwen3.6-35b-a3b"; } ];
          };
        };

        extraPackages = [
          micsSkills.calendar-cli
          micsSkills.db-cli
          micsSkills.gmaps-cli
          micsSkills.tasker-cli
          micsSkills.kagi-search
        ]
        ++ [
          pkgs.coreutils
          pkgs.curl
          pkgs.fd
          pkgs.file
          pkgs.git
          pkgs.hurl
          pkgs.jq
          pkgs.less
          pkgs.lynx
          pkgs.openssh
          pkgs.ripgrep
          pkgs.tree
          pkgs.unzip
          pkgs.python3
          pkgs.w3m
          pkgs.wget
          pkgs.yq-go
          pkgs.zip
        ];
      };

      mkContainer = name: uid: {
        "${name}".config = {
          users = {
            users.opencrow.uid = uid;
            groups.opencrow.gid = uid;
          };
          systemd.tmpfiles.rules = [
            "d /var/lib/${name}/.config 0750 opencrow opencrow -"
            "d /var/lib/${name}/.config/kagi 0750 opencrow opencrow -"
            "L+ /var/lib/${name}/.config/kagi/config.json - - - - ${kagiConfig}"
          ];
        };
      };
    in
    {
      imports = [ inputs.opencrow.nixosModules.default ];

      clan.core.vars.generators.opencrow-kagi = {
        files.session-link.secret = true;
        prompts.session-link.description = "Kagi session link for opencrow kagi-search skill";
        script = ''
          cp "$prompts/session-link" "$out/session-link"
        '';
      };

      clan.core.vars.generators.opencrow = {
        files.nostr-private-key.secret = true;
        files.nostr-public-key.secret = false;

        runtimeInputs = [ pkgs.nak ];

        script = ''
          sk=$(nak key generate)
          pk=$(nak key public "$sk")
          echo -n "$(nak encode nsec "$sk")" > "$out/nostr-private-key"
          echo -n "$(nak encode npub "$pk")" > "$out/nostr-public-key"
        '';
      };

      users.groups.opencrow.gid = 2000;
      users.groups.opencrow-signal.gid = 2001;

      preservation.preserveAt."/persist".directories = [
        {
          directory = "/var/lib/opencrow";
          user = "opencrow";
          group = "opencrow";
          mode = "0750";
        }
        {
          directory = "/var/lib/opencrow-signal";
          user = "2001";
          group = "opencrow-signal";
          mode = "0750";
        }
      ];

      containers = mkContainer "opencrow" 2000 // mkContainer "opencrow-signal" 2001;

      services.opencrow = commonInstance // {
        environment = commonInstance.environment // {
          OPENCROW_BACKEND = "nostr";
          OPENCROW_SOUL_FILE = "${./soul-dexter.md}";
          OPENCROW_NOSTR_RELAYS = localRelayUrl;
          OPENCROW_NOSTR_PRIVATE_KEY_FILE = "%d/nostr-private-key";
          OPENCROW_NOSTR_ALLOWED_USERS = "npub16le4pxhfvy04jwcp9rhw3ustkwt7sm0jydgq4lr3qderycrlm8ysjxmufc";
          OPENCROW_NOSTR_NAME = "dexter";
          OPENCROW_NOSTR_DISPLAY_NAME = "dexter";
          OPENCROW_NOSTR_ABOUT = "henlo";
        };

        credentialFiles = commonInstance.credentialFiles // {
          "nostr-private-key" = config.clan.core.vars.generators.opencrow.files.nostr-private-key.path;
        };

        instances.signal = commonInstance // {
          environment = commonInstance.environment // {
            OPENCROW_BACKEND = "signal";
            OPENCROW_SOUL_FILE = "${./soul-gismo.md}";
            OPENCROW_SIGNAL_ACCOUNT = "+4915251840217";
            OPENCROW_ALLOWED_USERS = "dcca284c-5b24-4eba-8e40-bb9649c1502c,c4c7789f-f5e0-4340-bb57-ffb4e412bbd9";
            OPENCROW_PI_PROVIDER = "openai-codex";
            OPENCROW_PI_MODEL = "gpt-5.5";
          };
        };
      };
    };
}
