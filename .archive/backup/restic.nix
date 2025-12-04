{
  lib,
  ...
}:
let
  storageBoxUser = "u499127-sub1";
  storageBoxHost = "${storageBoxUser}.your-storagebox.de";
  storageBoxPort = "23";
  repo = "sftp://${storageBoxUser}@${storageBoxHost}:${storageBoxPort}/hm-px-prd1";
in
{

  services.restic.backups.main = {
    # find latest snapshots and output their paths to backup
    dynamicFilesFrom = ''
      set -euo pipefail

      for dataset in apps backup shares; do
        snapdir="/mnt/tank/$dataset/.zfs/snapshot"

        # skip if directory doesn't exist
        [ -d "$snapdir" ] || continue

        latest=$(ls -1t "$snapdir" | head -1 || true)

        # skip if no snapshots yet
        [ -n "$latest" ] || continue

        echo "$snapdir/$latest"
      done
    '';

    paths = [ ];

    repository = lib.mkForce repo;
  };
}
