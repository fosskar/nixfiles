_: {
  imports = [ ../../../../modules/impermanence ];

  nixfiles.impermanence = {
    enable = true;
    rollbackType = "btrfs";
    btrfs.rootDeviceLabel = "nixos";
    manageSopsMount = true;
    directories = [
      "/var/cache/tailscale"
      "/var/lib/tailscale"
      "/var/lib/dmsgreeter"
    ];
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
