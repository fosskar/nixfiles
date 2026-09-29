package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// exit codes of ocrmypdf, see ocrmypdf.exceptions.ExitCode
const (
	exitInputFile      = 2
	exitAlreadyDoneOCR = 6
	exitEncryptedPDF   = 8
)

// ocr runs ocrmypdf in its default mode, which refuses any pdf that already
// has text on a page, so born-digital pdfs and this service's own output are
// never rewritten. skip is non-empty when the file is left alone.
//
// tagged pdfs are not refused: scanner apps produce them too, and a tagged
// office export still stops at the text check.
//
// ocrmypdf's output is not forwarded: ghostscript prints a pdf/a notice per
// overprint operation, up to tens of thousands of lines for one file, which
// made journald drop this service's own messages. only the last line is kept
// for the error of a failed run.
func ocr(ctx context.Context, languages, src, dst string) (skip string, err error) {
	cmd := exec.CommandContext(ctx, "ocrmypdf", "--output-type", "pdfa", "--tagged-pdf-mode", "ignore", "--language", languages, src, dst)
	out := &tail{max: 4096}
	cmd.Stdout = out
	cmd.Stderr = out
	err = cmd.Run()
	var exitErr *exec.ExitError
	if !errors.As(err, &exitErr) {
		return "", err
	}
	switch exitErr.ExitCode() {
	case exitAlreadyDoneOCR:
		return "already has text", nil
	case exitEncryptedPDF:
		return "encrypted", nil
	case exitInputFile:
		return "unreadable pdf", nil
	}
	return "", fmt.Errorf("ocrmypdf exited with %d: %s", exitErr.ExitCode(), out.lastLine())
}

// tail keeps the last max bytes written to it.
type tail struct {
	buf []byte
	max int
}

func (t *tail) Write(p []byte) (int, error) {
	t.buf = append(t.buf, p...)
	if len(t.buf) > t.max {
		t.buf = t.buf[len(t.buf)-t.max:]
	}
	return len(p), nil
}

func (t *tail) lastLine() string {
	s := strings.TrimSpace(string(t.buf))
	return s[strings.LastIndexByte(s, '\n')+1:]
}

// processedByOCRmyPDF reports whether the pdf was written by ocrmypdf, whose
// output names it as creator in plain text. such a file needs no second run:
// when ocr found no text on its pages, default mode would otherwise accept it
// again and every backfill would upload another identical version.
func processedByOCRmyPDF(path string) (bool, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return false, err
	}
	return bytes.Contains(data, []byte("OCRmyPDF")), nil
}
