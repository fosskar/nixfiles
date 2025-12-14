_: {
  imports = [ ../../modules/impermanence ];

  nixfiles.impermanence = {
    enable = true;
    rollbackType = "zfs";
    zfs.dataset = "znixos/root";
    directories = [
      "/var/log"
      "/var/cache"
      "/var/lib"
    ];
  };
}
