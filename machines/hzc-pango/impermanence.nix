_: {
  imports = [ ../../modules/impermanence ];

  nixfiles.impermanence = {
    enable = true;
    rollbackType = "btrfs";
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
