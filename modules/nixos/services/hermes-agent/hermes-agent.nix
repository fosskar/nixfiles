{ inputs, ... }:
{
  # hermes itself, nothing about where it runs. import it on a host to run it
  # there, or list it in an agent-vm to run it sealed off — see
  # modules/nixos/virtualization/agent-vm.nix.
  flake.modules.nixos.hermesAgent =
    {
      config,
      flake-self,
      pkgs,
      ...
    }:
    let
      stateDir = config.services.hermes-agent.stateDir;
    in
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;
        extraPackages = [
          pkgs.agent-browser
          pkgs.chromium
          pkgs.curl
        ];

        settings = {
          timezone = "Europe/Berlin";

          model = {
            # the only alias llama-cpp preloads; models-max = 1, so naming any
            # other one costs a model swap on the first request
            default = "qwen3.6-35b-a3b-mtp";
            provider = "custom";
            base_url = "https://llama-cpp.${flake-self.domains.local}/v1";
            api_key = "none";
            # what llama-cpp serves for this alias; hermes refuses anything
            # below 64k
            context_length = 131072;
          };
        };

        # the matrix domain is neither domains.local nor domains.public: mxids
        # live on fosskar.de, which delegates its client api to matrix.fosskar.eu
        environment = {
          MATRIX_HOMESERVER = "https://matrix.fosskar.eu";
          MATRIX_USER_ID = "@hermes:fosskar.de";
          MATRIX_ALLOWED_USERS = "@fosskar:fosskar.de";
          # fail closed rather than silently falling back to plaintext when
          # crypto cannot initialise. MATRIX_ENCRYPTION is the deprecated alias
          MATRIX_E2EE_MODE = "required";
          # a bootstrapped recovery key is written once and never logged; catch
          # it on the persistent volume instead of losing it
          MATRIX_RECOVERY_KEY_OUTPUT_FILE = "${stateDir}/matrix-recovery-key";
        };
      };

      # tool calls run as the service user, so the interactive cli has to as
      # well or it reads a different HERMES_HOME
      environment.shellAliases.hermes = "sudo -u hermes -H hermes";

      # what upstream's ubuntu container mode exists for: somewhere the agent
      # can pip/npm install at runtime
      systemd.tmpfiles.rules = [
        "d ${stateDir}/venv 0750 hermes hermes - -"
        "d ${stateDir}/npm 0750 hermes hermes - -"
      ];

      systemd.services.hermes-venv = {
        description = "writable pip venv for the agent";
        wantedBy = [ "hermes-agent.service" ];
        before = [ "hermes-agent.service" ];
        unitConfig.ConditionPathExists = "!${stateDir}/venv/bin/python";
        serviceConfig = {
          Type = "oneshot";
          User = "hermes";
          RemainAfterExit = true;
        };
        script = "${pkgs.python3}/bin/python3 -m venv ${stateDir}/venv";
      };

      users.users.hermes.packages = [
        pkgs.nodejs
        pkgs.python3
      ];

      environment.variables = {
        NPM_CONFIG_PREFIX = "${stateDir}/npm";
        VIRTUAL_ENV = "${stateDir}/venv";
      };
    };
}
