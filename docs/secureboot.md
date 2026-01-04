# secure boot (lanzaboote)

## setup

1. generate keys on target machine:

   ```bash
   ssh root@<machine>
   nix shell nixpkgs#sbctl -c sbctl create-keys
   ```

2. import lanzaboote module in machine config:

   ```nix
   imports = [ ../../modules/lanzaboote ];
   ```

3. deploy:

   ```bash
   clan machines update <machine>
   ```

4. reboot into UEFI (F2 on framework)

5. enable secure boot + clear keys:
   - security → secure boot → enable
   - "enforce all secure boot settings" (clears PK, KEK, db, dbx)
   - this puts secure boot in "setup mode"

6. boot into nixos, enroll keys:

   ```bash
   sudo sbctl enroll-keys --microsoft
   ```

7. reboot and verify:
   ```bash
   sbctl status  # should show: Secure Boot: enabled
   sbctl verify  # verifies all boot files signed
   ```

## notes

- `--microsoft` flag required for framework laptops (firmware updates via fwupd/LVFS are MS-signed)
- keys stored in `/var/lib/sbctl`, persisted via `nixfiles.persistence.directories`
- lanzaboote replaces systemd-boot, signs kernel + initrd automatically
