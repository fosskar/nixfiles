## Usage

```nix
inventory.instances.hermes = {
  module = {
    name = "hermes";
    input = "self";
  };
  roles.server.machines.nixbox.settings = {
    soul = "tars";                         # key into flake.llm.souls; omit for the agent's built-in default
    providers = { local.enable = true; openrouter.enable = true; };
    agentSettings = { };                   # merged over the service defaults
    matrix = { enable = true; userId = "@hermes:example.org"; allowedUsers = [ ... ]; };
    signal.enable = true;
    homeAssistant.enable = true;
    mcp.enable = true;                     # requires self.modules.nixos.mcp on the server host
  };
  roles.client.tags = [ "workstation" ];
};
```

Each instance is one deployment. A second instance with different settings
(other soul, no channels) deploys a second, independent agent.

## Overview

`hermes` runs the Hermes agent sealed on one server and connects Hermes Desktop on workstation clients to it. The service carries only mechanism; every deployment-specific fact — soul, model, channels, identity — is inventory settings. This homelab's agent policy (model, voice, search backend, plugins) is not a deployment fact and lives in `modules/nixos/services/hermes-agent/hermes-agent.nix`; `agentSettings` is merged over it.

The server role:

- builds the agent sandbox — `backend = "microvm"` (default, own kernel) or `"container"` (nspawn, same bridge posture) — with the engine and the channels enabled in settings (`matrix.nix`, `signal.nix`, `home-assistant.nix` under `modules/nixos/services/hermes-agent/`)
- derives the vars generator from the instance name (`<instance>-agent`) and prompts only for enabled channels and key-bearing providers
- stages the rendered `.env` into the sandbox
- creates the dashboard session token with clan vars and shares it read-only
- asks the sandbox to forward `127.0.0.1:<22100 + id>` on the server to port `9119` inside it; the sandbox module owns the transport (vsock for microvms, TCP over the bridge for containers)
- keeps the dashboard closed to the LAN

Souls live in `modules/llm/souls/` and are referenced by their `flake.llm.souls` key. The instance name is also the VM name; it must be at most 11 chars so interface names fit IFNAMSIZ.

The client role:

- installs Hermes Desktop and `hermes-desktop-remote`
- starts an SSH tunnel to the server when the user launches Hermes Desktop
- reads the dashboard token through the same SSH identity
- connects Hermes Desktop to the local tunnel endpoint

The service requires exactly one server role machine. Clients use the existing `root` SSH identity to reach that server. The existing `hermes gateway` service continues to provide Matrix access from phones.
