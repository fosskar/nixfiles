# nixbox physical disk bay map

Maps each physical drive bay in the nixbox chassis (JMCD 9-bay) to its drive
serial, pool, and SATA controller port. Use this to find which physical bay to
pull when ZED reports a faulted drive.

ZED fault emails name the drive by its `by-id` path (e.g.
`ata-WDC_WD60EFPX-68C5ZN0_WD-WX52D25NJV0E`). Take the serial from that path,
find it in the table, pull that bay.

## bay map

| bay | serial           | model                | pool         | controller port |
| --- | ---------------- | -------------------- | ------------ | --------------- |
| 1   | WD-WX92D15E77CU  | WD60EFPX 6TB         | tank         | 2c ata-6        |
| 2   | WD-WX52D25NJV0E  | WD60EFPX 6TB         | tank         | 2c ata-1        |
| 3   | WD-WX92D15E7K76  | WD60EFPX 6TB         | tank         | 2c ata-2        |
| 4   | WD-WX62D45R20TA  | WD60EFPX 6TB         | tank         | 2c ata-5        |
| 5   | —                | empty                | —            | —               |
| 6   | Z9CBK75S         | Seagate IronWolf 1TB | spare/backup | 2b ata-4        |
| 7   | 50026B7687522C31 | Kingston DC600M 960G | znixos (OS)  | 2b ata-3        |
| 8   | 50026B768755993B | Kingston DC600M 960G | znixos (OS)  | 2b ata-2        |
| 9   | —                | empty                | —            | —               |

- `tank`: 4x WD60EFPX raidz2 (data pool)
- `znixos`: 2x Kingston DC600M mirror (OS/boot pool)
- bay 6: Seagate IronWolf, not in any pool, spun down by `disk-power.nix`

## notes

- **Identify by serial, not bay LED.** The chassis backplane is passive: the
  controller is onboard AMD FCH AHCI with no enclosure management (`CAP.EMS=0`,
  no SES/SGPIO path). `ledctl`/`sg_ses` cannot drive locate LEDs. This table
  from physical label inspection is the source of truth.
- **The green activity LED works per-bay, but only for drives that drive SATA
  pin 11.** Pin 11 is dual-purpose in the SATA spec: activity-LED output _or_
  staggered-spin-up input. Seagate (IronWolf, bay 6) and the Kingston SSDs
  drive it as activity output, so their bay LED flashes on IO and is
  bay-correct (verified with random-read load). The **WD Red WD60EFPX drives
  (tank, bays 1-4) use pin 11 for power management instead and never output an
  activity signal**, so their bay LEDs stay dark even under heavy IO and even
  when healthy. This is a known WD-vs-Seagate pin-11 difference, purely
  cosmetic, not a fault and not fixable in software/firmware. Do not tape pin
  11 to "fix" it (the pin-3 / 3.3V Power Disable taping trick is a different
  issue). Net: the activity LED cannot locate or fault-indicate the tank WD
  drives — use this table for those.
- The LED is an activity indicator only, never a fault indicator: a dead drive
  just stops flashing (looks the same as idle). Trust `zpool status` for which
  drive faulted.
- **`sdX` names are not stable** across reboots. Serial / `by-id` is the stable
  key; ZFS imports pools by `by-id` (`boot.zfs.devNodes = "/dev/disk/by-id"`).
- `controller port` is the `/dev/disk/by-path` location: `2b` and `2c` are the
  two onboard AMD SATA controllers (`pci-0000:2b:00.0`, `pci-0000:2c:00.0`).

## failure procedure

1. ZED email reports a faulted drive with its `by-id` serial.
2. `zpool status <pool>` confirms which drive is DEGRADED/FAULTED.
3. Look up the serial in the table above to find the bay.
4. Pull that bay. raidz2 (`tank`) tolerates 2 drive failures; the mirror
   (`znixos`) tolerates 1.
5. Insert replacement, then `zpool replace <pool> <old-id> <new-id>` and wait
   for resilver to finish before any further drive removal.
