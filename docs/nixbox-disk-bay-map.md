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
| 5   | S2R6NX0HC26234K  | Samsung 850 EVO 250G | -            | 2b ata-1        |
| 6   | S4XBNF0M924716V  | Samsung 860 EVO 500G | -            | 2b ata-4        |
| 7   | 50026B7687522C31 | Kingston DC600M 960G | znixos (OS)  | 2b ata-3        |
| 8   | 50026B768755993B | Kingston DC600M 960G | znixos (OS)  | 2b ata-2        |
| 9   | Z9CBK75S         | Seagate IronWolf 1TB | spare/backup | not connected   |

- `tank`: 4x WD60EFPX raidz2 (data pool)
- `znixos`: 2x Kingston DC600M mirror (OS/boot pool)
- bays 5-6: Samsung SSDs, wiped (no partition table), not in any pool
- bay 9: Seagate IronWolf, not in any pool, spun down by `disk-power.nix`
  when connected. no SATA port is free for it (see ports below)

## notes

- **Identify by serial, not bay LED.** The controller is onboard AMD FCH AHCI
  with no enclosure management (`CAP.EMS=0`), wired to the backplane through
  SFF-8643 to 4x SATA reverse breakout cables, which carry no sideband. No
  SES/SGPIO path exists, so `ledctl`/`sg_ses` cannot drive locate LEDs. This
  table from physical label inspection is the source of truth.
- **The green activity LED works per-bay, but only for drives that drive SATA
  pin 11.** Pin 11 is dual-purpose in the SATA spec: activity-LED output _or_
  staggered-spin-up input. Seagate (IronWolf) and the Kingston SSDs
  drive it as activity output, so their bay LED flashes on IO and is
  bay-correct (verified with random-read load). The **WD Red WD60EFPX drives
  (tank, bays 1-4) use pin 11 for power management instead and never output an
  activity signal**, so their bay LEDs stay dark even under heavy IO and even
  when healthy. This is a known WD-vs-Seagate pin-11 difference, purely
  cosmetic, not a fault and not fixable in software/firmware. Do not tape pin
  11 to "fix" it (the pin-3 / 3.3V Power Disable taping trick is a different
  issue). Net: the activity LED cannot locate or fault-indicate the tank WD
  drives. Use this table for those.
- The LED is an activity indicator only, never a fault indicator: a dead drive
  just stops flashing (looks the same as idle). Trust `zpool status` for which
  drive faulted.
- **`sdX` names are not stable** across reboots. Serial / `by-id` is the stable
  key; ZFS imports pools by `by-id` (`boot.zfs.devNodes = "/dev/disk/by-id"`).
- `controller port` is the `/dev/disk/by-path` location: `2b` and `2c` are the
  two onboard AMD SATA controllers (`pci-0000:2b:00.0`, `pci-0000:2c:00.0`).
  The kernel registers 8 ports on each (`ata1`-`ata16`), but only 8 of the 16
  are wired to board connectors.

## backplane (JMCD 9S2)

From the JMCD9S2 user manual
(`https://ae-pic-a1.aliexpress-media.com/kf/Sf294e3b3ff194c7b84e7547302f96c2f2.pdf`):

- 12Gb SAS backplane with 2x SFF-8643 (bays 1-8) and 1x plain SATA connector
  (bay 9). Bay 9 has no SGPIO path in any wiring.
- Supported wiring: SATA ports with SFF-8643 to 4x SATA reverse cables (current
  setup), or an LSI HBA/RAID card with SFF-8643 to SFF-8087 or SFF-8643 to
  SFF-8643 cables.
- "SGPIO works only with LSI HBAs/RAID cards. Other HBA brands: read/write
  works, power LED works, but activity LED will not light." The manual does
  not mention locate or fault LEDs; whether `ledctl locate` works with an LSI
  card is untested.
- Backplane power needs at least 2 separate Molex cables; 3 recommended.

## ports and expansion (ASRock Rack X570D4U-2L2T/BCM)

From the board manual (`https://download.asrock.com/Manual/X570D4U-2L2T.pdf`):

- 8 SATA ports: 7 SATA plus `SATA_0` (DOM connector, also takes a normal SATA
  cable). All 8 are in use: bays 1-8.
- 2 M.2 (PCIe4.0 x4 or SATA), both used by the Optane SLOG drives.
- Slots, top to bottom: `SLOT6` PCIe4.0 x16 [CPU], `SLOT5` PCIe4.0 x1 [FCH],
  `SLOT4` PCIe4.0 x8 [CPU]. "SLOT6 auto-switch to PCIe4.0 x8 when SLOT4
  occupied".
- The RTX PRO 4000 (`2d:00.0`) reads `current_link_width` 8 of
  `max_link_width` 16, so the CPU lanes already run x8/x8.

An LSI SAS3008 HBA (e.g. 9300-8i, IT mode) in the free CPU slot with 2x
SFF-8643 to SFF-8643 cables would move bays 1-8 to the HBA, give them SGPIO
activity LEDs, and free all 8 onboard SATA ports for bay 9 and the two
internal 2.5" brackets.

## failure procedure

1. ZED email reports a faulted drive with its `by-id` serial.
2. `zpool status <pool>` confirms which drive is DEGRADED/FAULTED.
3. Look up the serial in the table above to find the bay.
4. Pull that bay. raidz2 (`tank`) tolerates 2 drive failures; the mirror
   (`znixos`) tolerates 1.
5. Insert replacement, then `zpool replace <pool> <old-id> <new-id>` and wait
   for resilver to finish before any further drive removal.
