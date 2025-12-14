_: {
  imports = [ ../../modules/impermanence ];

  nixfiles.impermanence = {
    enable = true;
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
