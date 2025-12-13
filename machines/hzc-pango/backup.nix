_: {
  nixfiles.borgbackup = {
    enable = true;
    useSnapshots = true;
    snapshotType = "btrfs";
  };
}
