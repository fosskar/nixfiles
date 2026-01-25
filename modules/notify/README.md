# notify module

sends push notifications via gotify when systemd services fail.

## how it works

1. adds `OnFailure=notify@%n.service` drop-in to all systemd services
2. when a service fails, `notify@<service>.service` triggers
3. notify service POSTs to local gotify with service name, exit code, result

## gotify bootstrap

on first boot, `gotify-bootstrap.service`:

- waits for gotify to be ready
- creates all configured applications via API
- saves tokens to `/var/lib/gotify-server/tokens/<app-name>`

tokens persist in gotify's state dir.

## adding applications

`systemd-notify` is always created. add more:

```nix
nixfiles.notify.gotify.applications = {
  grafana = "grafana alerts";
  backup = "backup notifications";
};
```

access token paths in other modules:

```nix
config.nixfiles.notify.gotify.tokenFile.grafana
# -> /var/lib/gotify-server/tokens/grafana
```

## notification content

```
🔴 <service> failed

Host: <hostname>
Result: <signal|exit-code|timeout>
Exit code: <number>
State: <failed|activating>
```

## notes

- `systemctl stop` = clean shutdown, no alert
- only actual failures trigger (non-zero exit, signal, timeout)
- services with `Restart=always` may show "activating" state (auto-restarting)
