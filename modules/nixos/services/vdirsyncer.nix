{
  flake.modules.nixos.vdirsyncer =
    {
      config,
      lib,
      options,
      ...
    }:
    let
      # simon's radicale principal (see collection-root/); holds the real data.
      radicaleUser = "3aa30ef9-033e-4821-b492-2cee2a94b45b";
      collectionsRoot = "/var/lib/radicale/collections/collection-root/${radicaleUser}";
      emailFile = config.clan.core.vars.generators.vdirsyncer-mailbox.files."email".path;
      passwordFile = config.clan.core.vars.generators.vdirsyncer-mailbox.files."password".path;
    in
    {
      config = {
        # offsite mirror of radicale calendars/contacts to mailbox.org.
        # radicale storage is read_only: vdirsyncer can never write back to the
        # primary, only push to mailbox.org. mailbox is a mirror, not versioned;
        # point-in-time recovery stays the server backup's job.
        clan.core.vars.generators.vdirsyncer-mailbox = {
          prompts.email = {
            description = "mailbox.org login email (DAV username)";
            type = "hidden";
            persist = true;
          };
          prompts.password = {
            description = "mailbox.org app-specific password (Settings -> Security)";
            type = "hidden";
            persist = true;
          };
          files."email" = {
            owner = "radicale";
            group = "radicale";
          };
          files."password" = {
            owner = "radicale";
            group = "radicale";
          };
          script = ''
            cp "$prompts/email" "$out/email"
            cp "$prompts/password" "$out/password"
          '';
        };

        services.vdirsyncer = {
          enable = true;
          jobs.mailbox-backup = {
            user = "radicale";
            group = "radicale";
            forceDiscover = true;
            timerConfig = {
              OnBootSec = "15m";
              OnUnitActiveSec = "1h";
            };
            config = {
              storages = {
                radicale_cal = {
                  type = "filesystem";
                  path = collectionsRoot;
                  fileext = ".ics";
                  read_only = true;
                };
                radicale_card = {
                  type = "filesystem";
                  path = collectionsRoot;
                  fileext = ".vcf";
                  read_only = true;
                };
                mailbox_cal = {
                  type = "caldav";
                  url = "https://dav.mailbox.org/";
                  "username.fetch" = [
                    "command"
                    "cat"
                    emailFile
                  ];
                  "password.fetch" = [
                    "command"
                    "cat"
                    passwordFile
                  ];
                };
                mailbox_card = {
                  type = "carddav";
                  url = "https://dav.mailbox.org/";
                  "username.fetch" = [
                    "command"
                    "cat"
                    emailFile
                  ];
                  "password.fetch" = [
                    "command"
                    "cat"
                    passwordFile
                  ];
                };
              };
              pairs = {
                calendars = {
                  a = "radicale_cal";
                  b = "mailbox_cal";
                  collections = [
                    "Family"
                    "Hobby"
                    "Personal"
                    "Work"
                  ];
                  metadata = [
                    "displayname"
                    "color"
                  ];
                };
                contacts = {
                  a = "radicale_card";
                  b = "mailbox_card";
                  collections = [ "contacts" ];
                  metadata = [ "displayname" ];
                };
              };
            };
          };
        };
      }
      // lib.optionalAttrs (options ? preservation) {
        # persist sync state so it doesn't re-upload everything after a rollback.
        # not backed up: regenerable by re-syncing from the CalDAV/CardDAV servers.
        preservation.preserveAt."/persist".directories = [
          {
            directory = "/var/lib/vdirsyncer";
            user = "radicale";
            group = "radicale";
          }
        ];
      };
    };
}
