_: {
  imports = [ ../../modules/persistence ];

  nixfiles.persistence = {
    enable = true;
    backend = "impermanence";
    rollback = {
      type = "btrfs";
      deviceLabel = "root";
    };
    manageSopsMount = true;
    directories = [
      "/var/lib/crowdsec"
      "/var/log"
      {
        directory = "/var/lib/private";
        mode = "0700";
      }
    ];
  };
}
