{ pkgs, ... }:
{
  # use clan's postgresql module for backup/restore integration
  clan.core.postgresql = {
    enable = true;

    databases = {
      vaultwarden = {
        create.enable = false; # vaultwarden module creates it
        restore.stopOnRestore = [ "vaultwarden.service" ];
      };
      immich = {
        create.enable = false; # immich module creates it
        restore.stopOnRestore = [
          "immich-server.service"
          "immich-machine-learning.service"
          "redis-immich.service"
        ];
      };
      paperless = {
        create.enable = false; # paperless module creates it
        restore.stopOnRestore = [
          "paperless-consumer.service"
          "paperless-scheduler.service"
          "paperless-task-queue.service"
          "paperless-web.service"
          "redis-paperless.service"
        ];
      };
      nextcloud = {
        create.enable = false; # nextcloud module creates it
        restore.stopOnRestore = [
          "phpfpm-nextcloud.service"
          "redis-nextcloud.service"
        ];
      };
    };

  };

  # set postgresql version (immich etc will add their extensions)
  services.postgresql.package = pkgs.postgresql_17;
}
