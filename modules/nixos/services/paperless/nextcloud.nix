{
  flake.modules.nixos.paperlessNextcloud =
    { config, ... }:
    let
      archiveDir = "${config.services.paperless.mediaDir}/documents/archive";
    in
    {
      fileSystems."/srv/paperless-archive" = {
        device = archiveDir;
        fsType = "fuse.bindfs";
        noCheck = true;
        options = [
          "ro"
          "force-user=nextcloud"
          "force-group=nextcloud"
          "perms=0000:u=rD"
          "x-systemd.requires-mounts-for=${archiveDir}"
        ];
      };
    };
}
