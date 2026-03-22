package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// copyToClipboard copies text to wayland clipboard using wl-copy
func copyToClipboard(text string) error {
	cmd := exec.Command("wl-copy", text)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("wl-copy failed: %w", err)
	}
	return nil
}

// notify sends a desktop notification
func notify(title, body string) {
	// find icon relative to binary location
	iconPath := findIcon()
	args := []string{}
	if iconPath != "" {
		args = append(args, "-i", iconPath)
	}
	args = append(args, title, body)
	cmd := exec.Command("notify-send", args...)
	_ = cmd.Run()
}

// findIcon returns the absolute path to the icon svg
func findIcon() string {
	exe, err := os.Executable()
	if err != nil {
		return ""
	}
	// resolve symlinks (.live-ocr-wrapped -> actual binary)
	exe, err = filepath.EvalSymlinks(exe)
	if err != nil {
		return ""
	}
	// binary is at <store-path>/bin/.live-ocr-wrapped
	// icon is at <store-path>/share/icons/hicolor/scalable/apps/live-ocr.svg
	storeDir := filepath.Dir(filepath.Dir(exe))
	icon := filepath.Join(storeDir, "share", "icons", "hicolor", "scalable", "apps", "live-ocr.svg")
	if _, err := os.Stat(icon); err == nil {
		return icon
	}
	return ""
}

// wordsToString joins selected words with spaces
func wordsToString(words []Word) string {
	parts := make([]string, len(words))
	for i, w := range words {
		parts[i] = w.Text
	}
	return strings.Join(parts, " ")
}
