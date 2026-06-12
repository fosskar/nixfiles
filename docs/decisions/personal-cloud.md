# opencloud over nextcloud + paperless

this repo migrated from [nextcloud](https://nextcloud.com) (file sync/share, calendar, apps) plus [paperless-ngx](https://docs.paperless-ngx.com) (document management) to a single [opencloud](https://opencloud.eu) deployment.

## why leave nextcloud

three problems, roughly equal weight:

- maintenance burden: php monolith with a fragile app ecosystem. apps broke on upgrades and several needed custom packaging and pinning in this repo (`user_oidc` uid mapping, workflow-ocr, news, assistant).
- performance: slow ui, heavy stack.
- scope mismatch: only a fraction of nextcloud was in use; most of the platform was dead weight.

## why drop paperless

paperless-ngx is a full document-management system: ocr ingest pipelines, tagging, correspondents, archive serial numbers. that layer turned out to be unneeded - plain files in folders plus full-text search (including ocr of scans, via opencloud's tika integration) cover the actual usage. paperless was over-engineering for this setup, same scope-mismatch theme as nextcloud.

## why opencloud

- single go binary instead of a php stack - fewer moving parts.
- posix storage driver: files stay plain files on disk, not an opaque db-managed layout. data outlives the software.
- oidc-native auth, fits the existing idp without plugin glue.
- packaged in nixpkgs.
- community fork of ocis, not bound to ownCloud GmbH governance.
- tika integration provides full-text and ocr search over stored files.

## technical comparison

| aspect          | nextcloud                                                                         | opencloud                                                                           |
| --------------- | --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| runtime         | php-fpm + webserver + sql db + redis + cron jobs                                  | single go binary (embedded services)                                                |
| metadata        | sql db (`oc_filecache`); files on disk invalid without db sync (`occ files:scan`) | posix storage driver: filesystem is the source of truth, external changes picked up |
| auth            | session/password core, oidc via app plugin (`user_oidc`)                          | oidc-native, no plugin layer                                                        |
| upgrades        | sequential major-version migrations, app compatibility matrix                     | binary swap + automatic service migrations                                          |
| extension model | php apps loaded into the monolith (shared failure domain)                         | none; integrations are separate services                                            |
| search/ocr      | app plugins (workflow-ocr) inside php runtime                                     | tika sidecar, out of process                                                        |

the metadata point is the structural one: with nextcloud the database co-owns file state, so backup/restore must keep db and disk consistent and out-of-band file changes corrupt the cache. with the posix driver the files alone are the state - backup is a filesystem backup, and data outlives the software.

## role mapping

| role                         | before        | after                                    |
| ---------------------------- | ------------- | ---------------------------------------- |
| file sync/share              | nextcloud     | opencloud                                |
| document archive + search    | paperless-ngx | opencloud folders + tika ocr/search      |
| caldav/carddav               | nextcloud     | radicale (wired in the opencloud module) |
| feed reader (nextcloud news) | nextcloud app | miniflux (standalone service)            |

## accepted tradeoffs

- young, fast-moving project: needed workarounds in this repo (oidc identity stabilization, refresh-token lifespan, permission-fixer service, disabled web extensions).
- no app ecosystem: each need gets a standalone service instead of a nextcloud app. deliberate - small sharp tools over one platform - but more services to run.
- weaker mobile/desktop clients than nextcloud.
- no dms features (tagging, correspondents, ingest workflows) - accepted because unused, see above.

## repo wiring

- `modules/nixos/services/opencloud.nix`: opencloud, tika, radicale.
- imported on `nixbox` (`machines/nixbox/configuration.nix`).
