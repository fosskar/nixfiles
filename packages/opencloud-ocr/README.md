# opencloud-ocr

adds a text layer to scanned pdfs in opencloud. each pdf without text is run through `ocrmypdf --output-type pdfa` and uploaded back as a new version of the same file, so the text is selectable and searchable outside opencloud too. the original stays restorable in the versions panel. tika still does the full-text indexing inside opencloud.

## how it works

- consumes `events.UploadReady` from the `main-queue` jetstream stream through the durable consumer `opencloud-ocr`
- logs in to the reva gateway as the opencloud service account (`OC_SERVICE_ACCOUNT_ID`, `OC_SERVICE_ACCOUNT_SECRET`)
- skips failed uploads, non-pdfs, events without an executing user (changes made directly on disk) and its own uploads
- runs `ocrmypdf` in default mode with `deu+eng`. exit 6 (page already has text), 8 (encrypted) and 2 (unreadable) leave the file alone, so born-digital pdfs and mixed pdfs are never rewritten
- uploads with `If-Match` on the etag read before the download. if the file changed, is locked, was deleted or is over quota, the job is dropped and the user's version wins
- gateway errors are retried up to 5 times, one minute apart. ocrmypdf failures are not retried

addresses are fixed to the opencloud defaults: nats `127.0.0.1:9233`, gateway `127.0.0.1:9142`.

## usage

```bash
opencloud-ocr           # consume upload events
opencloud-ocr backfill  # process every pdf already in a personal or project space, then exit
```

both read the service account from `$CREDENTIALS_DIRECTORY/envfile`.

on nixos, `modules/nixos/services/opencloud/ocr.nix` runs the consumer as `opencloud-ocr.service`. the backfill is a oneshot unit that is only started by hand:

```bash
systemctl start opencloud-ocr-backfill
journalctl -u opencloud-ocr-backfill -f
```

## side effects

- every processed pdf gets a new version uploaded by the service account
- the modification date changes to the time of processing
- storage use for a processed file roughly doubles, since the original is kept as a version
- sync clients download the new version

## update go dependencies

```bash
cd packages/opencloud-ocr/opencloud-ocr
go get -u ./...
go mod tidy
```

then set `vendorHash = lib.fakeHash;` in `package.nix`, rebuild, and replace with the correct hash from the error output.

## build

```bash
nix build .#opencloud-ocr
```

tests run during the build.
