_: {
  imports = [ ../../modules/persistence ];

  nixfiles.persistence = {
    enable = true;
    backend = "impermanence";
    rollback = {
      type = "zfs";
      dataset = "znixos/root";
      poolImportService = "zfs-import-znixos.service";
    };
    directories = [
      "/var/log"
      "/var/cache"
      "/var/lib"
    ];
  };
}
