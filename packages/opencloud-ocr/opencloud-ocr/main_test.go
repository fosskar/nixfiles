package main

import (
	"context"
	"encoding/base64"
	"os"
	"path/filepath"
	"testing"
)

const serviceAccount = "708de56f-1c2f-4f5c-8ef1-ad9d8ce0ee07"

// payloads in the shape captured from main-queue on opencloud 7.5.0
const (
	userUpload = `{"UploadID":"u1","Filename":"Scan.PDF","ExecutingUser":{"id":{"idp":"https://auth.example","opaque_id":"3aa30ef9-033e-4821-b492-2cee2a94b45b","type":1},"username":"simon"},"FileRef":{"resource_id":{"storage_id":"80b03aa7-eb9e-4067-9d3e-c0a593e9b545","opaque_id":"440f07fe-3f8c-485c-90fd-1be4c7d390fe","space_id":"440f07fe-3f8c-485c-90fd-1be4c7d390fe"},"path":"./ocr-test/Scan.PDF"},"Failed":false,"IsVersion":false}`
	ownUpload  = `{"UploadID":"u2","Filename":"scan.pdf","ExecutingUser":{"id":{"idp":"none","opaque_id":"708de56f-1c2f-4f5c-8ef1-ad9d8ce0ee07"}},"FileRef":{"resource_id":{"storage_id":"80b03aa7-eb9e-4067-9d3e-c0a593e9b545","opaque_id":"440f07fe-3f8c-485c-90fd-1be4c7d390fe","space_id":"440f07fe-3f8c-485c-90fd-1be4c7d390fe"},"path":"./ocr-test/scan.pdf"},"Failed":false,"IsVersion":true}`
	watcher    = `{"FileRef":{"resource_id":{"storage_id":"80b03aa7-eb9e-4067-9d3e-c0a593e9b545","opaque_id":"4bce8b1a-7dca-4126-a38f-4afcc44f5362","space_id":"440f07fe-3f8c-485c-90fd-1be4c7d390fe"}},"IsVersion":true}`
	failed     = `{"UploadID":"u3","Filename":"scan.pdf","ExecutingUser":{"id":{"opaque_id":"3aa30ef9-033e-4821-b492-2cee2a94b45b"}},"FileRef":{"resource_id":{"space_id":"s"},"path":"./scan.pdf"},"Failed":true}`
	notPDF     = `{"UploadID":"u4","Filename":"photo.jpg","ExecutingUser":{"id":{"opaque_id":"3aa30ef9-033e-4821-b492-2cee2a94b45b"}},"FileRef":{"resource_id":{"space_id":"s"},"path":"./photo.jpg"}}`
)

func envelopeOf(eventType, payload string) []byte {
	return []byte(`{"ID":"x","Topic":"main-queue","Metadata":{"eventtype":"` + eventType + `"},"Payload":"` +
		base64.StdEncoding.EncodeToString([]byte(payload)) + `"}`)
}

func TestSkipReason(t *testing.T) {
	for _, tc := range []struct {
		name, payload, want string
	}{
		{"user upload", userUpload, ""},
		{"own upload", ownUpload, "own upload"},
		{"posix watcher", watcher, "not a pdf"},
		{"failed upload", failed, "upload failed"},
		{"not a pdf", notPDF, "not a pdf"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ev, err := parseUploadReady(envelopeOf("events.UploadReady", tc.payload))
			if err != nil || ev == nil {
				t.Fatalf("parse: %v %v", ev, err)
			}
			if got := skipReason(ev, serviceAccount); got != tc.want {
				t.Fatalf("skipReason = %q, want %q", got, tc.want)
			}
		})
	}
}

func TestWatcherEventWithPDFName(t *testing.T) {
	ev, err := parseUploadReady(envelopeOf("events.UploadReady", `{"Filename":"scan.pdf","FileRef":{"resource_id":{"space_id":"s"}}}`))
	if err != nil {
		t.Fatal(err)
	}
	if got := skipReason(ev, serviceAccount); got != "no executing user" {
		t.Fatalf("skipReason = %q", got)
	}
}

func TestParseUploadReady(t *testing.T) {
	ev, err := parseUploadReady(envelopeOf("events.UploadReady", userUpload))
	if err != nil {
		t.Fatal(err)
	}
	if ev.FileRef.GetResourceId().GetSpaceId() != "440f07fe-3f8c-485c-90fd-1be4c7d390fe" || ev.FileRef.GetPath() != "./ocr-test/Scan.PDF" {
		t.Fatalf("file reference not decoded: %v", ev.FileRef)
	}
	ev, err = parseUploadReady(envelopeOf("events.BytesReceived", userUpload))
	if err != nil || ev != nil {
		t.Fatalf("other event types must be ignored, got %v %v", ev, err)
	}
	if _, err := parseUploadReady([]byte("not json")); err == nil {
		t.Fatal("expected an error for undecodable data")
	}
}

func TestOCRExitCodes(t *testing.T) {
	for _, tc := range []struct {
		code    string
		skip    string
		wantErr bool
	}{
		{"0", "", false},
		{"2", "unreadable pdf", false},
		{"6", "already has text", false},
		{"8", "encrypted", false},
		{"7", "", true},
	} {
		t.Run(tc.code, func(t *testing.T) {
			bin := t.TempDir()
			script := "#!/bin/sh\nexit " + tc.code + "\n"
			if err := os.WriteFile(filepath.Join(bin, "ocrmypdf"), []byte(script), 0o755); err != nil {
				t.Fatal(err)
			}
			t.Setenv("PATH", bin)
			skip, err := ocr(context.Background(), languages, "in.pdf", "out.pdf")
			if skip != tc.skip || (err != nil) != tc.wantErr {
				t.Fatalf("ocr = %q, %v", skip, err)
			}
		})
	}
}

func TestReadServiceAccount(t *testing.T) {
	path := filepath.Join(t.TempDir(), "envfile")
	content := "ADMIN_PASSWORD=a\nOC_SERVICE_ACCOUNT_ID=id\nOC_SERVICE_ACCOUNT_SECRET=se=cret\n"
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}
	id, secret, err := readServiceAccount(path)
	if err != nil || id != "id" || secret != "se=cret" {
		t.Fatalf("got %q %q %v", id, secret, err)
	}
	if err := os.WriteFile(path, []byte("ADMIN_PASSWORD=a\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, _, err := readServiceAccount(path); err == nil {
		t.Fatal("expected an error without service account")
	}
}

func TestOCRErrorKeepsLastLine(t *testing.T) {
	bin := t.TempDir()
	script := "#!/bin/sh\ni=0\nwhile [ $i -lt 5000 ]; do echo 'overprint mode not set'; i=$((i+1)); done\necho 'PdfiumError: Failed to fill bitmap rectangle.' >&2\nexit 15\n"
	if err := os.WriteFile(filepath.Join(bin, "ocrmypdf"), []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", bin)
	_, err := ocr(context.Background(), languages, "in.pdf", "out.pdf")
	want := "ocrmypdf exited with 15: PdfiumError: Failed to fill bitmap rectangle."
	if err == nil || err.Error() != want {
		t.Fatalf("err = %v, want %q", err, want)
	}
}

func TestProcessedByOCRmyPDF(t *testing.T) {
	dir := t.TempDir()
	for name, content := range map[string]string{
		"ocrmypdf.pdf": "%PDF-1.7\n1 0 obj << /Creator (OCRmyPDF 17.11.0 / OCRmyPDF fpdf2 + Tesseract OCR 5.5.3) >>",
		"scan.pdf":     "%PDF-1.4\n1 0 obj << /Creator (Canon iR-ADV) >>",
	} {
		path := filepath.Join(dir, name)
		if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
			t.Fatal(err)
		}
		got, err := processedByOCRmyPDF(path)
		if err != nil || got != (name == "ocrmypdf.pdf") {
			t.Fatalf("%s: got %v, %v", name, got, err)
		}
	}
}

func TestOCRIgnoresTaggedPDFs(t *testing.T) {
	bin := t.TempDir()
	script := "#!/bin/sh\ncase \" $* \" in *' --tagged-pdf-mode ignore '*) exit 0 ;; esac\nexit 7\n"
	if err := os.WriteFile(filepath.Join(bin, "ocrmypdf"), []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", bin)
	if _, err := ocr(context.Background(), languages, "in.pdf", "out.pdf"); err != nil {
		t.Fatalf("ocrmypdf was not called with --tagged-pdf-mode ignore: %v", err)
	}
}
