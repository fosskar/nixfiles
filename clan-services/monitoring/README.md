## Usage

```nix
inventory.instances = {
  monitoring = {
    module = {
      name = "monitoring";
      input = "self";
    };
    roles.server.machines."server".settings = {
      extraTelegrafTargets = [ "openwrt.lan:9273" ];
    };
    roles.client.tags.server = { };
  };
};
```

## Overview

`monitoring` provides central metrics/log storage with Telegraf, VictoriaMetrics, VictoriaLogs, and Grafana.

Server role:

- requires exactly one server machine
- imports repo monitoring modules for exporters, Grafana, VictoriaLogs, and VictoriaMetrics
- builds VictoriaMetrics scrape configs from client role assignments
- optionally provisions Grafana dashboards
- enables node exporter and ZFS exporter by default

Client role:

- requires exactly one server machine
- imports the Telegraf module
- exposes a Prometheus client output on `listenPort`
- opens the Telegraf port on `ygg` for non-server machines

## Settings

### `server`

- `grafana.enable`: enable Grafana. defaults to `true`.
- `retentionPeriod`: VictoriaMetrics retention in months. defaults to `3`.
- `extraTelegrafTargets`: extra Telegraf Prometheus endpoints, as `host:port`.
- `extraScrapeConfigs`: extra VictoriaMetrics scrape configs.
- `extraDashboardsDir`: extra Grafana dashboard directory to provision.
- `exporter.node.enable`: enable node exporter. defaults to `true`.
- `exporter.zfs.enable`: enable ZFS exporter when ZFS is enabled. defaults to `true`.

### `client`

- `listenPort`: Telegraf Prometheus client listen port. defaults to `9273`.
- `host`: override scrape host for this client. defaults to `<machine>.<clan-domain>` or `127.0.0.1` on the server machine.
