package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
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
func ocr(ctx context.Context, languages, src, dst string) (skip string, err error) {
	cmd := exec.CommandContext(ctx, "ocrmypdf", "--output-type", "pdfa", "--language", languages, src, dst)
	cmd.Stdout = os.Stderr
	cmd.Stderr = os.Stderr
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
	return "", fmt.Errorf("ocrmypdf exited with %d", exitErr.ExitCode())
}
