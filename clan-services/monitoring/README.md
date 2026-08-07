## Usage

```nix
inventory.instances = {
  monitoring = {
    module = {
      name = "monitoring";
      input = "self";
    };
    roles.server.machines."nixbox".settings = {
      extraTelegrafTargets = [ "openwrt.lan:9273" ];
    };
    roles.client.tags = [ "server" ];
  };
};
```

The server machine must also hold the client role. The server is monitored as an
ordinary client, over `127.0.0.1`. An assertion fails the build when the server
machine has no client role.

## Overview

`monitoring` provides central metrics/log storage with Telegraf, VictoriaMetrics, VictoriaLogs, and Grafana.

The instance requires exactly one server machine. `manifest.constraints` enforces this.

Server role:

- imports repo monitoring modules for exporters, Grafana, VictoriaLogs, and VictoriaMetrics
- builds VictoriaMetrics scrape configs from client role assignments
- provisions the Grafana dashboards in `dashboards/`
- opens the VictoriaLogs port on `ygg`
- enables Grafana, node exporter, and ZFS exporter

Client role:

- imports the Telegraf module
- exposes a Prometheus client output on `listenPort`
- uploads the journal to VictoriaLogs on the server machine
- opens the Telegraf port on `ygg` for non-server machines

## Settings

### `server`

- `retentionPeriod`: VictoriaMetrics retention in months. defaults to `3`.
- `extraTelegrafTargets`: extra Telegraf Prometheus endpoints, as `host:port`.
- `exporter.node.enable`: enable node exporter. defaults to `true`.
- `exporter.zfs.enable`: enable ZFS exporter when ZFS is enabled. defaults to `true`.

Scrape jobs for `extraTelegrafTargets` label the host `target`, not `machine`.
`dashboards/unbound_adguardhome.json` selects on `target`. The other dashboards
select on `machine`.

### `client`

- `listenPort`: Telegraf Prometheus client listen port. defaults to `9273`.
- `host`: override the scrape host for this client. when unset, the server
  machine uses `127.0.0.1` and every other machine uses `<machine>.<clan-domain>`.
