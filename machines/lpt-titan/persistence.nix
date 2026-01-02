_: {
  imports = [ ../../modules/persistence ];

  nixfiles.persistence = {
    enable = true;
    backend = "preservation";
    rollback = {
      type = "bcachefs";
      subvolume = "@root";
    };
    manageSopsMount = true;
  };

  # fix home directory ownership issues
  systemd.tmpfiles.rules = [
    "d /home/simon 0755 simon users -"
    "d /home/simon/.cache 0755 simon users -"
    "d /home/simon/.config 0755 simon users -"
    "d /home/simon/.local 0755 simon users -"
    "d /home/simon/.local/share 0755 simon users -"
    "Z /home/simon - simon users - -"
  ];
}
