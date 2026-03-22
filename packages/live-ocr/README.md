# live-ocr

interactive OCR overlay for wayland. takes a screenshot, runs OCR (tesseract), and shows an overlay where you can select detected words and copy them to clipboard.

## usage

```bash
live-ocr              # region select (default), then OCR overlay
live-ocr --window     # capture focused window
live-ocr --fullscreen # capture full screen
live-ocr image.png    # OCR an existing image file
live-ocr -            # read image from stdin
```

## overlay controls

| action                | key/mouse           |
| --------------------- | ------------------- |
| select word           | click               |
| deselect word         | click selected word |
| select multiple       | ctrl+click          |
| select range          | shift+click         |
| select area           | drag                |
| add area to selection | ctrl+drag           |
| select all            | ctrl+a              |
| copy & quit           | enter / ctrl+c      |
| quit                  | escape              |

## dependencies

runtime (wrapped automatically via nix):

- grim — screenshot
- slurp — region selection
- wl-clipboard — clipboard
- libnotify — notifications
- tesseract — OCR engine

## update go dependencies

```bash
cd packages/live-ocr/live-ocr
go get -u ./...
go mod tidy
```

then set `vendorHash = lib.fakeHash;` in `default.nix`, rebuild, and replace with the correct hash from the error output.

## build

```bash
nix build .#live-ocr
./result/bin/live-ocr
```
