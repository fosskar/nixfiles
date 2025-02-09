{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    openiscsi
  ];

  services.openiscsi = {
    enable = true;
    name = "iqn.2025-02.k3s.cluster.iscsi:${config.networking.hostName}";
  };

  # Symlink nsenter and iscsiadm so Longhorn can find them
  system.activationScripts.fixLonghorn = ''
    mkdir -p /usr/bin
    ln -sf /run/current-system/sw/bin/nsenter /usr/bin/nsenter
    ln -sf /run/current-system/sw/bin/iscsiadm /usr/bin/iscsiadm
  '';
}
