{
  flake.modules.nixos.server =
    { pkgs, ... }:
    let
      layers = pkgs.writeText "scx-layers.json" (
        builtins.toJSON [
          {
            name = "latency";
            comment = "front door and user-facing request paths; may preempt everything else";
            matches = [
              [ { CgroupPrefix = "system.slice/caddy.service"; } ]
              [ { CgroupPrefix = "system.slice/postgresql.service"; } ]
              [ { CgroupPrefix = "system.slice/continuwuity.service"; } ]
              [ { CgroupPrefix = "system.slice/opencloud.service"; } ]
              [ { CgroupPrefix = "system.slice/seerr.service"; } ]
              [ { CgroupPrefix = "system.slice/garage.service"; } ]
              [ { CgroupPrefix = "system.slice/p2p-ssh-iroh-iroh-ssh.service"; } ]
            ];
            kind.Open = {
              slice_us = 5000;
              preempt = true;
              weight = 400;
            };
          }
          {
            name = "vm";
            comment = "microvms, talos, and nspawn containers; opaque guests, never preempt the front door";
            matches = [
              [ { CgroupPrefix = "machine.slice/"; } ]
              [ { CgroupPrefix = "system.slice/system-microvm.slice/"; } ]
              [ { CgroupPrefix = ''system.slice/system-microvm\x2dvirtiofsd.slice/''; } ]
              [ { CgroupPrefix = "system.slice/talos-vm.service"; } ]
            ];
            kind.Grouped = {
              util_range = [
                0.7
                0.9
              ];
              cpus_range_frac = [
                0.0
                0.75
              ];
              slice_us = 20000;
              preempt = false;
              weight = 200;
            };
          }
          {
            name = "batch";
            comment = "cpu hogs that must never starve the latency layer: inference, photo ml, text extraction";
            matches = [
              [ { CgroupPrefix = "system.slice/llama-cpp.service"; } ]
              [ { CgroupPrefix = "system.slice/system-immich.slice/"; } ]
              [ { CgroupPrefix = "system.slice/tika.service"; } ]
            ];
            kind.Confined = {
              util_range = [
                0.8
                0.95
              ];
              cpus_range_frac = [
                0.0
                0.5
              ];
              slice_us = 20000;
              preempt = false;
              weight = 50;
            };
          }
          {
            name = "telemetry";
            comment = "metrics and log shipping; background, small share";
            matches = [
              [ { CgroupPrefix = "system.slice/victoriametrics.service"; } ]
              [ { CgroupPrefix = "system.slice/victorialogs.service"; } ]
              [ { CgroupPrefix = "system.slice/telegraf.service"; } ]
              [ { CgroupPrefix = "system.slice/prometheus-node-exporter.service"; } ]
              [ { CgroupPrefix = "system.slice/beszel-agent.service"; } ]
            ];
            kind.Confined = {
              util_range = [
                0.8
                0.95
              ];
              cpus_range_frac = [
                0.0
                0.25
              ];
              slice_us = 20000;
              preempt = false;
              weight = 20;
            };
          }
          {
            name = "normal";
            comment = "catch-all: everything else, including kernel threads and admin sessions";
            matches = [ [ ] ];
            kind.Open = {
              slice_us = 20000;
              preempt = false;
              weight = 100;
            };
          }
        ]
      );
    in
    {
      services.scx = {
        enable = true;
        package = pkgs.scx.rustscheds;
        scheduler = "scx_layered";
        extraArgs = [ "f:${layers}" ];
      };
    };
}
