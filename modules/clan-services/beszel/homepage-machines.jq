# inputs (slurped): $systems, $details, $pools, $smart as pocketbase list
# responses, $stats as one latest 1m system_stats record per system
($systems[0].items | map({ (.id): .name }) | add // { }) as $names
| ($details[0].items | map({ (.system): . }) | add // { }) as $details
| ($stats | map({ (.system): .stats }) | add // { }) as $stats
| {
    updated: (now | todate),
    machines: [
      $systems[0].items[]
      | ($details[.id] // { }) as $d
      | ($stats[.id] // { }) as $x
      | {
          name,
          status,
          cpu: .info.cpu,
          mem: .info.mp,
          disk: .info.dp,
          load: (.info.la // [ ]),
          uptime: .info.u,
          os: $d.os_name,
          kernel: $d.kernel,
          cpuModel: $d.cpu,
          cores: $d.cores,
          memTotal: $d.memory,
          temps: ($x.t // { }),
          gpus: [ ($x.g // { })[] | { name: .n, memUsed: .mu, memTotal: .mt } ]
        }
    ],
    pools: [
      $pools[0].items[]
      | {
          system: $names[.system],
          # btrfs filesystems are named b:<uuid> and carry the label in display_name
          name: (if (.display_name // "") != "" then .display_name else .name end),
          kind: (if (.name | startswith("b:")) then "btrfs" else "zfs" end),
          health,
          size,
          alloc,
          scrub,
          vdevs: [ .vdevs[]?.name ],
          datasets: [ .datasets[]? | { name, used, avail } ]
        }
    ],
    drives: [
      $smart[0].items[]
      | { system: $names[.system], name, model, state, capacity, temp, hours }
    ]
  }
