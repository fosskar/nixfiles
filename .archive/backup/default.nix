{ config, pkgs, ... }:
let
  storageBoxUser = "u499127-sub1";
  storageBoxHost = "${storageBoxUser}.your-storagebox.de";
  storageBoxPort = "23";
in
{
  # add storage box ssh host key
  programs.ssh = {
    knownHosts."${storageBoxHost}" = {
      hostNames = [ "[${storageBoxHost}]:${storageBoxPort}" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
    };
  };

  environment.systemPackages = [ pkgs.restic ];

  services.restic.backups.main = {
    paths = [ ];

    repository = "sftp://${storageBoxUser}@${storageBoxHost}:${storageBoxPort}/${config.networking.hostName}";

    passwordFile = config.sops.secrets."restic-encryption-password".path;

    extraOptions = [
      "sftp.command='ssh -p ${storageBoxPort} -i ${
        config.sops.secrets."storagebox-ssh-key".path
      } -o IdentitiesOnly=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=3 ${storageBoxUser}@${storageBoxHost} -s sftp'"
    ];

    # schedule
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };

    # retention
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 1"
      "--keep-monthly 1"
      "--keep-yearly 1"
    ];
    initialize = true;
  };
}
