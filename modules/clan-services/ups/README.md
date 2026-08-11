## Usage

```nix
inventory.instances = {
  ups = {
    module = {
      name = "ups";
      input = "self";
    };
    roles = {
      primary.machines."nixbox" = { };
      secondary.machines."nixworker" = { };
    };
  };
};
```

## Roles

- `primary`: the machine with the UPS data cable (USB). Runs the `usbhid-ups`
  driver, `upsd` in `netserver` mode (listens on `::` plus `127.0.0.1` for the
  local telegraf poller; the firewall opens 3493 on the yggdrasil `ygg`
  interface only) and the primary `upsmon`. Declares a gatus TCP probe on
  `<primary>.s:3493`. Shuts down last and powers off the UPS outlets.
- `secondary`: a machine drawing power from the same UPS but without a data
  cable. Runs `upsmon` in `netclient` mode, monitors the primary over the
  yggdrasil mesh (`eaton-ellipse@<primary>.s`) with `powerValue = 1`, and shuts
  itself down on low battery before the primary kills the outlets.

## Hardware

Eaton Ellipse PRO. Only the COM/USB cable carries UPS telemetry; it lives on the
primary. The chassis RJ45 `IN`/`OUT` ports are data-line surge passthrough, not a
network management interface, so the UPS is not reachable over IP.

## Shared secret

The upsmon password is a shared clan var (`generators.ups`, `share = true`) so
secondaries authenticate to the primary's `upsd`. Both roles define the
generator; regenerate with `clan vars generate` after first deploy.

## Dumb loads on the UPS (e.g. network switch)

Devices on the UPS that cannot run `upsmon` (switches, modems) need no
configuration. They keep running on battery and only lose power when the primary
powers off the UPS outlets at the end of the shutdown sequence.

A secondary whose mesh link to the primary runs _through_ such a switch stays
correct because of the shutdown order: secondaries shut down first, then the
primary issues FSD and cuts the outlets. By the time the switch loses power, the
secondaries are already down, so they never lose the monitoring link while still
running.
