## Usage

```nix
inventory.instances.hermes = {
  module = {
    name = "hermes";
    input = "self";
  };
  roles.server.machines.nixbox = { };
  roles.client.tags = [ "workstation" ];
};
```

## Overview

`hermes` connects Hermes Desktop on workstation clients to the Hermes Agent VM on one server.

The server role:

- creates the dashboard session token with clan vars
- shares the token read-only with the agent VM
- forwards `127.0.0.1:22100` on the server through vsock to port `9119` inside the VM
- keeps the dashboard closed to the LAN

The client role:

- installs Hermes Desktop and `hermes-desktop-remote`
- starts an SSH tunnel to the server when the user launches Hermes Desktop
- reads the dashboard token through the same SSH identity
- connects Hermes Desktop to the local tunnel endpoint

The service requires exactly one server role machine. Clients use the existing `root` SSH identity to reach that server. The existing `hermes gateway` service continues to provide Matrix access from phones.
