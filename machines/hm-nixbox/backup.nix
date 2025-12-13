_: {
  nixfiles.borgbackup = {
    enable = true;
    folders = [
      "/persist"
      "/tank/apps"
      "/tank/shares"
    ];
    useSnapshots = true;
    snapshotType = "zfs";
  };
}
