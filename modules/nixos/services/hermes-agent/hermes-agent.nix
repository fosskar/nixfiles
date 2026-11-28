{ inputs, ... }:
{
  # the engine plus this homelab's agent policy: model, voice, search backend,
  # plugins. identity, channels and skill selection come from the clan service
  # composing this with its channel features
  flake.modules.nixos.hermesAgent =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.hermes-agent;
      inherit (cfg) stateDir;

      rtk = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.rtk;

      # the preset id /v1/models reports, not its alias: hermes lists the
      # configured name next to the discovered id, so an alias shows the one
      # model twice in the picker
      localModel = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:Q4_K_XL";

      # generated, not vendored, so the plugin tracks the pinned rtk. `rtk
      # rewrite` is the single source of truth; the plugin only bridges
      # hermes' pre_tool_call payload to it
      rtkPlugin = pkgs.runCommand "rtk-rewrite" { nativeBuildInputs = [ rtk ]; } ''
        export HOME="$PWD"
        rtk init -g --agent hermes
        cp -r "$HOME/.hermes/plugins/rtk-rewrite" "$out"
      '';

      # top-level scalar of a flat yaml file; enough for catalog entries and
      # plugin manifests, including the json-styled ones (hermes-terminal)
      yamlField =
        file: key:
        let
          matches = lib.filter (m: m != null) (
            map (line: builtins.match " *\"?${key}\"?: *\"?([^\",]*)\"?,? *" line) (
              lib.splitString "\n" (builtins.readFile file)
            )
          );
        in
        if matches == [ ] then "" else lib.head (lib.head matches);

      # the catalog entry is the pin: repo + 40-hex sha, reviewed upstream and
      # bumped with the hermes-agent input. a full rev keeps fetchGit pure.
      # plugins.enabled matches the manifest name, which need not equal the
      # catalog key (hermes-memory-wiki ships as memory-wiki)
      catalogPlugin =
        name:
        let
          entry = "${inputs.hermes-agent}/plugin-catalog/${name}.yaml";
          src = fetchGit {
            url = yamlField entry "repo";
            rev = yamlField entry "sha";
            allRefs = true;
          };
          root = "${src}/${yamlField entry "subdir"}";
        in
        {
          package = pkgs.runCommand name { } "cp -r ${root} $out";
          pluginName = yamlField "${root}/plugin.yaml" "name";
        };

      catalogPlugins = map catalogPlugin cfg.catalogPlugins;

      # every soul in modules/llm/souls, for the agent to list and apply
      soulTemplates = pkgs.linkFarm "hermes-soul-templates" (
        lib.mapAttrsToList (name: path: {
          name = "${name}.md";
          inherit path;
        }) flake-self.llm.souls
      );
      soulTemplatesDir = "${stateDir}/.hermes/soul-templates";
      soulTemplatesSkill = pkgs.writeTextDir "SKILL.md" ''
        ---
        name: soul-templates
        description: List the soul templates (characters, personas, identities) this agent can take on, switch its own soul to one, or start a new bot with one.
        ---

        # Soul templates

        A soul is an agent's identity: its SOUL.md. Ready-made souls live in
        `${soulTemplatesDir}/`, one `<name>.md` each. Use this when someone
        asks which souls, characters or personas are available, wants you to
        become one, or wants a new bot with one.

        ## List

        List the `*.md` files in `${soulTemplatesDir}/` and give each name with
        a one-line summary from its first lines.

        ## Become one

        Copy the template over your own soul:

            cp ${soulTemplatesDir}/<name>.md "$HERMES_HOME/SOUL.md"

        The soul is read when a session starts, so it applies from the next
        new chat. Tell the user to open one.

        ## New bot with a soul

        1. `hermes profile create <bot-name>`
        2. `cp ${soulTemplatesDir}/<name>.md "$HERMES_HOME/profiles/<bot-name>/SOUL.md"`

        The bot shows up in the webapp's bot list within about 30 seconds.
      '';

      settingsFormat = pkgs.formats.yaml { };

      # hermes' managed scope (hermes_cli/managed_scope.py): these keys are
      # pinned over HERMES_HOME/config.yaml and .env, and the agent and the
      # dashboard cannot change them. upstream's settings and environment stay
      # empty, so activation copies no nix value into HERMES_HOME and a key
      # removed here leaves nothing behind
      managedDir = pkgs.linkFarm "hermes-managed" {
        "config.yaml" = settingsFormat.generate "hermes-managed-config.yaml" cfg.managed.settings;
        ".env" = pkgs.writeText "hermes-managed.env" (
          lib.concatLines (lib.mapAttrsToList (name: value: "${name}=${value}") cfg.managed.environment)
        );
      };

      defaults = {
        timezone = "Europe/Berlin";
        terminal.backend = "local";
        # local, in-process; the piper dependency group below ships piper-tts
        tts.provider = "piper";
        # the gpu whisper server on nixbox, through its caddy route on :443;
        # it needs no key, but a hostname base_url is not treated as local
        stt = {
          # hermes defaults to "en"; "" lets whisper detect the language
          language = "";
          provider = "openai";
          openai = {
            base_url = "https://whisper.${flake-self.domains.local}/v1";
            api_key = "not-needed";
            model = flake-self.whisperServer.model;
          };
        };
        # hermes only runs a chromium from PATH on termux; elsewhere it would
        # download its own build, which does not run on nixos
        browser.executable_path = lib.getExe pkgs.chromium;
        # own searxng instead of the paid search apis hermes defaults to
        web.search_backend = "searxng";
        # standalone plugins are opt-in; bundled platform/backend ones
        # (matrix, searxng) auto-load and are not affected by this list
        plugins.enabled = [
          "disk-cleanup"
          "rtk-rewrite"
        ]
        ++ map (plugin: plugin.pluginName) catalogPlugins;
        # built-in MEMORY.md/USER.md only; an instance can add a provider plugin
        memory.provider = "";
        # summarise old turns instead of hitting the context wall
        compression.enabled = true;
        # its default preset names openai-codex and openrouter models
        moa.presets.default.enabled = false;
        display.show_reasoning = false;
        display.message_reactions = true;
        # no metrics upload to nous, and the consent dialog cannot turn it on
        telemetry.shared_metrics = {
          enabled = false;
          send = false;
        };
      }
      // lib.optionalAttrs (cfg.fastModel != null) {
        # background helper calls on the small model instead of the main one
        auxiliary = lib.genAttrs [
          "approval"
          "background_review"
          "compression"
          "curator"
          "goal_judge"
          "group_router"
          "kanban_decomposer"
          "mcp"
          "memory_query_rewrite"
          "monitor"
          "profile_describer"
          "title_generation"
          "triage_specifier"
          "tts_audio_tags"
        ] (_: cfg.fastModel);
        # advanced-delegation: a subagent may pick the fast route; one that
        # picks none runs on the main model
        delegation = {
          backend = "model_map";
          backends.model_map.options = [
            (
              {
                name = "fast";
                description = "Quick and cheap: lookups, summaries, short single-step tasks.";
              }
              // cfg.fastModel
            )
          ];
        };
      }
      // lib.optionalAttrs cfg.localProvider.enable {
        providers.local = {
          name = "Local";
          api = "https://llama-cpp.${flake-self.domains.local}/v1";
          api_key = "no-key-required";
          default_model = localModel;
          context_length = null;
        };
        # null context_length: hermes reads llama.cpp's per-slot meta.n_ctx from
        # /v1/models, so the window follows the llamaCpp module. the explicit null
        # overrides stale pins left in the writable HERMES_HOME/config.yaml
        model = {
          default = localModel;
          provider = "local";
          context_length = null;
        };
      };
    in
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      options.services.hermes-agent = {
        localProvider.enable = lib.mkEnableOption "the homelab llama-cpp endpoint as the default model provider";

        fastModel = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                provider = lib.mkOption { type = lib.types.str; };
                model = lib.mkOption { type = lib.types.str; };
              };
            }
          );
          default = null;
          example = {
            provider = "opencode-go";
            model = "glm-5.3-flash";
          };
          description = "small model for helper calls (compression, titles, ...) and a fast subagent route.";
        };

        soul = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "starting SOUL.md, copied only while the agent has none; the agent may change it afterwards.";
        };

        catalogPlugins = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "entries of hermes' plugin-catalog/ to install and enable, by catalog name.";
        };

        skillDirs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "directories handed to the agent as skills.external_dirs.";
        };

        overrides = lib.mkOption {
          type = lib.types.attrsOf lib.types.raw;
          default = { };
          description = ''
            merged over this module's settings defaults. precedence is spelled
            out here rather than left to module order.
          '';
        };

        managed = {
          settings = lib.mkOption {
            inherit (settingsFormat) type;
            default = { };
            description = "config.yaml keys pinned through hermes' managed scope.";
          };

          environment = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = ".env entries pinned through hermes' managed scope. not secret: the store is world-readable.";
          };
        };
      };

      config = {
        services.hermes-agent = {
          enable = true;
          catalogPlugins = lib.mkIf (cfg.fastModel != null) [ "advanced-delegation" ];
          skillDirs = [ "${soulTemplatesSkill}" ];
          addToSystemPackages = true;

          # upstream commits version 0.0.0 and only release jobs stamp the real
          # one; the flake package keeps 0.0.0, which fails every catalog
          # plugin's requires_hermes. the latest release tag the pinned input
          # contains; bump it when the input passes a new release
          package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
            version = "0.23.4";
          };

          # piper-tts for tts.provider; it is an optional extra outside the default package
          extraDependencyGroups = [ "piper" ];

          # symlinked into HERMES_HOME/plugins and gated by plugins.enabled
          # above; both halves are required or the hook silently never registers
          extraPlugins = [ rtkPlugin ] ++ map (plugin: plugin.package) catalogPlugins;

          extraPackages = [
            rtk
            # lazy optional-dep installs into HERMES_LAZY_INSTALL_TARGET go
            # through uv; without it the pip tier fails on the store env
            pkgs.uv
            pkgs.local.blogwatcher-cli
            pkgs.curl
            pkgs.gh
            pkgs.gitMinimal
            pkgs.himalaya
            # bitwarden logins for the agent's vault backend; hermes calls bw, rbw does not fit
            pkgs.bitwarden-cli
          ];

          # skillDirs comes from the deployment's skill selection, so it wins
          # over overrides
          managed.settings = lib.recursiveUpdate (lib.recursiveUpdate defaults cfg.overrides) (
            lib.optionalAttrs (cfg.skillDirs != [ ]) { skills.external_dirs = cfg.skillDirs; }
          );

          managed.environment.SEARXNG_URL = "https://search.${flake-self.domains.local}/";
        };

        # HERMES_MANAGED=false below lifts upstream's blanket refusal of
        # config writes; managedDir pins only the declared keys. hermes update
        # stays refused by its own /nix/store check

        # upstream's setup merges config.yaml as root and only chmods it, so a
        # fresh state dir leaves it root:root and the gateway cannot read it.
        # on first boot the user does not exist yet during activation; the
        # ExecStartPre below covers that boot
        system.activationScripts.hermes-agent-config-owner = lib.stringAfter [ "hermes-agent-setup" ] ''
          if ${pkgs.coreutils}/bin/id ${cfg.user} >/dev/null 2>&1; then
            ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${stateDir}/.hermes/config.yaml
          fi
        '';

        # -i, not -H: a login shell resets PATH to hermes' own profile. with the
        # caller's PATH the agent's packages are not found and unreadable /root
        # entries turn "command not found" into EACCES
        # the hermes user (the webapp terminal) runs the cli directly: its
        # service sets NoNewPrivileges, so sudo refuses there
        environment.interactiveShellInit = ''
          if [ "$(id -un)" != ${cfg.user} ]; then
            alias hermes='sudo -iu hermes env HERMES_MANAGED=false HERMES_MANAGED_DIR=${managedDir} HERMES_LAZY_INSTALL_TARGET=${stateDir}/lazy-deps NPM_CONFIG_PREFIX=${stateDir}/npm VIRTUAL_ENV=${stateDir}/venv hermes'
          fi
        '';

        # what upstream's ubuntu container mode exists for: somewhere the agent
        # can pip/npm install at runtime
        systemd.tmpfiles.rules = [
          "d ${stateDir}/venv 0750 hermes hermes - -"
          "d ${stateDir}/npm 0750 hermes hermes - -"
          "d ${stateDir}/lazy-deps 0750 hermes hermes - -"
          # opt out of seeding the bundled skill catalog; only hermes' essential skills get copied
          "f ${stateDir}/.hermes/.no-bundled-skills 0640 hermes hermes - -"
          "L+ ${soulTemplatesDir} - - - - ${soulTemplates}"
        ]
        # the soul is only the starting identity: C copies it when SOUL.md is
        # missing, before hermes would seed its own, and never overwrites the
        # agent's edits. z makes the copy from the read-only store writable
        ++ lib.optionals (cfg.soul != null) [
          "C ${stateDir}/.hermes/SOUL.md - - - - ${cfg.soul}"
          "z ${stateDir}/.hermes/SOUL.md 0644 ${cfg.user} ${cfg.group} -"
        ]
        ++ [
          # webapp/desktop ui preferences, seeded once: simple interface mode.
          # f never overwrites, so later changes from the webapp stay
          "f ${stateDir}/.hermes/ui-preferences.json 0660 hermes hermes - ${
            builtins.toJSON {
              version = 1;
              revision = 1;
              generation = "nix-seed";
              values."hermes.desktop.interfaceMode.v1" = "simple";
            }
          }"
        ];

        # bw has no server setting outside its own state, and only accepts a
        # new server while logged out; the login itself stays a one-time
        # `bw login` in the agent's terminal
        systemd.services.hermes-bitwarden-server =
          let
            server = "https://vault.${flake-self.domains.local}";
          in
          {
            description = "point the bitwarden cli at vaultwarden";
            wantedBy = [ "hermes-agent.service" ];
            before = [ "hermes-agent.service" ];
            path = [
              pkgs.bitwarden-cli
              pkgs.jq
            ];
            environment.HOME = stateDir;
            serviceConfig = {
              Type = "oneshot";
              User = cfg.user;
              Group = cfg.group;
              RemainAfterExit = true;
            };
            script = ''
              # a first run prints "creating it instead" lines before the json
              status="$(bw status --nointeraction | tail -n 1)"
              if [ "$(jq -r .status <<<"$status")" = unauthenticated ] \
                && [ "$(jq -r .serverUrl <<<"$status")" != ${server} ]; then
                bw config server ${server}
              fi
            '';
          };

        systemd.services.hermes-venv = {
          description = "writable pip venv for the agent";
          wantedBy = [ "hermes-agent.service" ];
          before = [ "hermes-agent.service" ];
          serviceConfig = {
            Type = "oneshot";
            User = "hermes";
            RemainAfterExit = true;
          };
          # the venv symlinks its interpreter from the store; after a python
          # bump the old path is gone and site-packages target the wrong abi,
          # so rebuild instead of repairing in place
          script = ''
            want="$(readlink -f ${pkgs.python3}/bin/python3)"
            have="$(readlink -f ${stateDir}/venv/bin/python 2>/dev/null || true)"
            if [ "$have" != "$want" ]; then
              rm -rf ${stateDir}/venv
              install -d -m 0750 ${stateDir}/venv
              ${pkgs.python3}/bin/python3 -m venv ${stateDir}/venv
            fi
          '';
        };

        users.users.hermes.linger = true;
        users.users.hermes.packages = [
          pkgs.nodejs
          pkgs.python3
        ];

        # NPM_CONFIG_PREFIX and VIRTUAL_ENV only tell the installers where to
        # write; without their bin dirs on PATH the agent cannot run what it
        # installed, not even pip itself
        systemd.services.hermes-agent = {
          serviceConfig.PAMName = "login";
          # "+" runs as root
          serviceConfig.ExecStartPre = lib.mkBefore [
            "+${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${stateDir}/.hermes/config.yaml"
            # hermes stages a plugin's desktop half by copying it; from the read-only
            # store the copy cannot take its marker, and the failed staging dir
            # cannot be removed either, so one leaks on every reconcile
            "+${pkgs.writeShellScript "hermes-desktop-plugins-staging-cleanup" ''
              # absent until hermes first installs a desktop plugin
              [ -d ${stateDir}/.hermes/desktop-plugins ] || exit 0
              ${pkgs.findutils}/bin/find ${stateDir}/.hermes/desktop-plugins -maxdepth 1 -name '.*.staging-*' \
                -exec ${pkgs.coreutils}/bin/chmod -R u+w {} + \
                -exec ${pkgs.coreutils}/bin/rm -rf {} +
            ''}"
          ];
          environment = {
            # system users otherwise get a session that does not start a user manager.
            XDG_SESSION_CLASS = "background";
            HERMES_MANAGED = lib.mkForce "false";
            HERMES_MANAGED_DIR = "${managedDir}";
            HERMES_LAZY_INSTALL_TARGET = "${stateDir}/lazy-deps";
            NPM_CONFIG_PREFIX = "${stateDir}/npm";
            VIRTUAL_ENV = "${stateDir}/venv";
          };
          path = lib.mkBefore [
            "${stateDir}/venv"
            "${stateDir}/npm"
          ];
        };
      };
    };
}
