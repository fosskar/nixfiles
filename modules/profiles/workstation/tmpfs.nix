{ lib, ... }:
{
  # tmpfs for /tmp - faster, less SSD wear
  boot.tmp = {
    useTmpfs = lib.mkDefault true;
    tmpfsSize = lib.mkDefault "50%";
  };

  # redirect nix builds to /var/tmp to avoid OOM with tmpfs
  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";
}
