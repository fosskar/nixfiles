## Usage

```nix
inventory.instances.hermes = {
  module = {
    name = "hermes";
    input = "self";
  };
  roles.server.machines.nixbox.settings = {
    soul = "tars";                         # key into flake.llm.souls; omit for the agent's built-in default
    webapp.enable = true;                  # https://hermes.<local domain>, authelia oidc
    providers = { local.enable = true; openrouter.enable = true; };
    agentSettings = { };                   # merged over the service defaults
    matrix = { enable = true; userId = "@hermes:example.org"; allowedUsers = [ ... ]; };
    signal.enable = true;
    telegram = { enable = true; allowedUsers = [ "123456789" ]; };
    homeAssistant.enable = true;
    mcp.allow = [ "calendar.*" ];          # requires self.modules.nixos.mcp on the server host
  };
  roles.client.tags = [ "workstation" ];
};
```

Each instance is one deployment. A second instance with different settings
(other soul, no channels) deploys a second, independent agent.

## Overview

`hermes` runs the Hermes agent sealed in a fencr sandbox on one server, serves its webapp, and installs Hermes Desktop on workstation clients. The service carries only mechanism; every deployment-specific fact (soul, model, channels, identity) is inventory settings. This homelab's agent policy (model, voice, search backend, plugins) is not a deployment fact and lives in `modules/nixos/services/hermes-agent/hermes-agent.nix`; `agentSettings` is merged over it.

The server role:

- builds the agent sandbox with the engine and the channels enabled in settings (`matrix.nix`, `signal.nix`, `telegram.nix`, `home-assistant.nix` under `modules/nixos/services/hermes-agent/`)
- derives the vars generator from the instance name (`<instance>-agent`) and prompts only for enabled channels and key-bearing providers
- stages the rendered `.env` into the sandbox; provider keys stay on the host in fencr credentials
- with `webapp.enable`: the gateway serves the webapp on the guest address, port 9120; fencr opens that port to the host; caddy serves `https://<instance>.<local domain>`; authelia registers the public pkce client `hermes-<instance>` under the `admins` policy

The instance name is also the VM name; it must be at most 11 chars so interface names fit IFNAMSIZ.

The client role installs Hermes Desktop with `hermes-desktop-remote`, which seeds the app's first connection to the server's webapp with oauth sign-in. The service requires exactly one server role machine and `webapp.enable` on it.
