_: {
  imports = [ ../../modules/impermanence ];

  nixfiles.impermanence = {
    enable = true;
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
