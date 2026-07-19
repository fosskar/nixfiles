{
  flake.modules.nixos.vdirsyncer =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      # simon's radicale principal (see collection-root/); holds the real data.
      radicaleUser = "3aa30ef9-033e-4821-b492-2cee2a94b45b";
      collectionsRoot = "/var/lib/radicale/collections/collection-root/${radicaleUser}";
      stagingDir = "/run/vdirsyncer-staging";
      calendarNames = [
        "Family"
        "Hobby"
        "Personal"
        "Work"
      ];
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
                  path = "${stagingDir}/events";
                  fileext = ".ics";
                  read_only = true;
                };
                radicale_todo = {
                  type = "filesystem";
                  path = "${stagingDir}/todos";
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
                mailbox_todo = {
                  type = "caldav";
                  # "Aufgaben" task folder; the only mailbox collection accepting VTODO.
                  url = "https://dav.mailbox.org/caldav/MzU/";
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
                  # radicale is the read-only source of truth; mirror always wins.
                  conflict_resolution = "a wins";
                  # OX rewrites items on store (adds SEQUENCE/CLASS/PRIORITY), which
                  # vdirsyncer sees as a b-side change. default partial_sync "revert"
                  # re-uploads forever (and 412s once OX bumps SEQUENCE); ignore it.
                  partial_sync = "ignore";
                  # mailbox.org stopped exposing name-based hrefs (2026-07);
                  # collections are matched by id, so pin [alias, radicale, mailbox-id].
                  collections = [
                    [
                      "Family"
                      "Family"
                      "Y2FsOi8vMC80NA"
                    ]
                    [
                      "Hobby"
                      "Hobby"
                      "Y2FsOi8vMC80NQ"
                    ]
                    [
                      "Personal"
                      "Personal"
                      "Y2FsOi8vMC80Ng"
                    ]
                    [
                      "Work"
                      "Work"
                      "Y2FsOi8vMC80Nw"
                    ]
                  ];
                  metadata = [
                    "displayname"
                    "color"
                  ];
                };
                contacts = {
                  a = "radicale_card";
                  b = "mailbox_card";
                  conflict_resolution = "a wins";
                  partial_sync = "ignore";
                  collections = [
                    [
                      "contacts"
                      "contacts"
                      "48"
                    ]
                  ];
                  metadata = [ "displayname" ];
                };
                # mailbox calendars reject VTODO (supported-calendar-component),
                # so staging splits tasks out and mirrors them flat into Aufgaben.
                todos = {
                  a = "radicale_todo";
                  b = "mailbox_todo";
                  conflict_resolution = "a wins";
                  partial_sync = "ignore";
                  collections = null;
                };
              };
            };
          };
        };
        systemd.services."vdirsyncer@mailbox-backup".serviceConfig = {
          RuntimeDirectory = "vdirsyncer-staging";
          ExecStartPre = pkgs.writeShellScript "vdirsyncer-stage" ''
            set -eu
            rm -rf ${stagingDir}/events ${stagingDir}/todos
            mkdir -p ${stagingDir}/todos
            stage() {
              # OX bumps its SEQUENCE counter on every store and 412s any PUT whose
              # SEQUENCE is lower, so radicale-side edits would deadlock (CAL-4121).
              # pinning a large constant makes every upload win; radicale untouched.
              ${pkgs.gawk}/bin/awk '
                /^BEGIN:(VEVENT|VTODO)/ { inComp = 1; seen = 0 }
                /^SEQUENCE/ && inComp   { print "SEQUENCE:9000\r"; seen = 1; next }
                /^END:(VEVENT|VTODO)/ && inComp { if (!seen) print "SEQUENCE:9000\r"; inComp = 0 }
                { print }
              ' "$1" > "$2"
            }
            for coll in ${lib.concatStringsSep " " calendarNames}; do
              mkdir -p "${stagingDir}/events/$coll"
              for f in "${collectionsRoot}/$coll"/*.ics; do
                [ -e "$f" ] || continue
                if grep -q '^BEGIN:VTODO' "$f"; then
                  # mailbox rejects recurring tasks (WEBDAV-1000); don't mirror them.
                  if ${pkgs.gawk}/bin/awk '/^BEGIN:VTODO/{t=1} t && /^RRULE/{exit 1} /^END:VTODO/{t=0}' "$f"; then
                    stage "$f" "${stagingDir}/todos/''${f##*/}"
                  fi
                else
                  stage "$f" "${stagingDir}/events/$coll/''${f##*/}"
                fi
              done
            done
          '';
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
