{
  flake.modules.nixos.hermesAgent =
    {
      inputs,
      ...
    }:
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      environment.shellAliases.hermes = "sudo -u hermes -H hermes";

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;

        settings = {
          timezone = "Europe/Berlin";

          terminal.cwd = "/var/lib/hermes/workspace";

          model = {
            default = "openai-codex/gpt-5.5";
          };
        };

        environment = {
          SIGNAL_ACCOUNT = "+4915251840217";
          SIGNAL_ALLOWED_USERS = "dcca284c-5b24-4eba-8e40-bb9649c1502c";
          SIGNAL_HTTP_URL = "http://127.0.0.1:18081";
        };
      };
    };
}
