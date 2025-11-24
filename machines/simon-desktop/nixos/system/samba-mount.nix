{ config, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.cifs-utils ];

  fileSystems."/mnt/shares/simon" = {
    device = "//192.168.10.104/simon";
    fsType = "cifs";
    options =
      let
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,user,users";
      in
      [ "${automount_opts},credentials=${config.sops.secrets."samba".path},uid=1000,gid=100" ];
  };

  fileSystems."/mnt/shares/shared" = {
    device = "//192.168.10.104/shared";
    fsType = "cifs";
    options =
      let
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,user,users";
      in
      [ "${automount_opts},credentials=${config.sops.secrets."samba".path},uid=1000,gid=100" ];
  };
}
