package main

import (
	"fmt"
	"os"

	"github.com/otiai10/gosseract/v2"
)

// Word represents a detected word with its bounding box
type Word struct {
	Text       string
	X, Y, W, H int
	Confidence float64
}

// runOCR performs OCR on image data and returns detected words with bounding boxes
func runOCR(imgData []byte) ([]Word, error) {
	// write image to temp file (gosseract needs a file path)
	tmpFile, err := os.CreateTemp("", "live-ocr-*.png")
	if err != nil {
		return nil, fmt.Errorf("creating temp file: %w", err)
	}
	defer os.Remove(tmpFile.Name())

	if _, err := tmpFile.Write(imgData); err != nil {
		tmpFile.Close()
		return nil, fmt.Errorf("writing temp file: %w", err)
	}
	tmpFile.Close()

	client := gosseract.NewClient()
	defer client.Close()

	client.SetImage(tmpFile.Name())
	// get word-level bounding boxes
	boxes, err := client.GetBoundingBoxes(gosseract.RIL_WORD)
	if err != nil {
		return nil, fmt.Errorf("OCR bounding boxes: %w", err)
	}

	var words []Word
	for _, box := range boxes {
		if box.Word == "" {
			continue
		}
		w := Word{
			Text:       box.Word,
			X:          box.Box.Min.X,
			Y:          box.Box.Min.Y,
			W:          box.Box.Max.X - box.Box.Min.X,
			H:          box.Box.Max.Y - box.Box.Min.Y,
			Confidence: float64(box.Confidence),
		}
		words = append(words, w)
	}

	return words, nil
}
