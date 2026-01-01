{ pkgs, ... }:
{
  # bcachefs filesystem support
  boot = {
    supportedFilesystems = [ "bcachefs" ];
    initrd.systemd.enable = true;
  };

  environment.systemPackages = [ pkgs.bcachefs-tools ];
}
