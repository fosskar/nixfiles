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

      commonInstance = {
        enable = true;

        package = inputs.opencrow.packages.${pkgs.stdenv.hostPlatform.system}.opencrow;
        piPackage = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

        skills.web = "${config.services.opencrow.package}/share/opencrow/skills/web";

        extensions = {
          memory = inputs.opencrow.packages.${pkgs.stdenv.hostPlatform.system}.extension-memory;
          reminders = inputs.opencrow.packages.${pkgs.stdenv.hostPlatform.system}.extension-reminders;
        };

        environment = {
          TZ = "Europe/Berlin";
          OPENCROW_PI_PROVIDER = "llama-cpp";
          OPENCROW_PI_MODEL = "granite4.1-8b";
          OPENCROW_SOUL_FILE = "${./soul.md}";
        };

        piModels = {
          providers.llama-cpp = {
            baseUrl = "https://llama-cpp.${config.domains.local}/v1";
            api = "openai-completions";
            apiKey = "dummy";
            models = [ { id = "granite4.1-8b"; } ];
          };
        };

        extraPackages = with pkgs; [
          coreutils
          curl
          fd
          file
          git
          hurl
          jq
          less
          lynx
          openssh
          ripgrep
          tree
          unzip
          python3
          w3m
          wget
          yq-go
          zip
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
          ];
        };
      };
    in
    {
      imports = [ inputs.opencrow.nixosModules.default ];

      clan.core.vars.generators.opencrow = {
        files.nostr-private-key.secret = true;
        files.nostr-public-key.secret = false;

        runtimeInputs = with pkgs; [ nak ];

        script = ''
          sk=$(nak key generate)
          pk=$(nak key public "$sk")
          echo -n "$(nak encode nsec "$sk")" > "$out/nostr-private-key"
          echo -n "$(nak encode npub "$pk")" > "$out/nostr-public-key"
        '';
      };

      users.groups.opencrow.gid = 2000;
      users.groups.opencrow-signal.gid = 2001;

      containers = mkContainer "opencrow" 2000 // mkContainer "opencrow-signal" 2001;

      services.opencrow = commonInstance // {
        environment = commonInstance.environment // {
          OPENCROW_BACKEND = "nostr";
          OPENCROW_NOSTR_RELAYS = localRelayUrl;
          OPENCROW_NOSTR_PRIVATE_KEY_FILE = "%d/nostr-private-key";
          OPENCROW_NOSTR_ALLOWED_USERS = "npub16le4pxhfvy04jwcp9rhw3ustkwt7sm0jydgq4lr3qderycrlm8ysjxmufc";
          OPENCROW_NOSTR_NAME = "dexter";
          OPENCROW_NOSTR_DISPLAY_NAME = "dexter";
          OPENCROW_NOSTR_ABOUT = "henlo";
        };

        credentialFiles."nostr-private-key" =
          config.clan.core.vars.generators.opencrow.files.nostr-private-key.path;

        instances.signal = commonInstance // {
          environment = commonInstance.environment // {
            OPENCROW_BACKEND = "signal";
            OPENCROW_SIGNAL_ACCOUNT = "+4915251840217";
            OPENCROW_ALLOWED_USERS = "dcca284c-5b24-4eba-8e40-bb9649c1502c";
          };
        };
      };
    };
}
