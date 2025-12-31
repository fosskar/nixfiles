_: {
  imports = [ ../../modules/borgbackup ];

  nixfiles.borgbackup = {
    enable = true;
    useSnapshots = true;
    snapshotType = "btrfs";
  };
}
