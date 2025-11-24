_: {
  imports = [
    ../../modules/backup
  ];

  services.restic.backups.main = {
    paths = [ "/var/lib/pangolin" ];
  };
}
