package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	fullscreen := flag.Bool("fullscreen", false, "capture full screen instead of region")
	window := flag.Bool("window", false, "capture focused window")
	output := flag.String("output", "", "capture a specific output/monitor")
	flag.Parse()

	// if positional arg given, use as image file
	var imgPath string
	if flag.NArg() > 0 {
		imgPath = flag.Arg(0)
	}

	// capture screenshot if no image file given
	var imgData []byte
	var err error

	if imgPath == "-" {
		// read from stdin
		imgData, err = os.ReadFile("/dev/stdin")
		if err != nil {
			fmt.Fprintf(os.Stderr, "error reading stdin: %v\n", err)
			os.Exit(1)
		}
	} else if imgPath != "" {
		// read from file
		imgData, err = os.ReadFile(imgPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "error reading file: %v\n", err)
			os.Exit(1)
		}
	} else {
		// take screenshot (region by default)
		imgData, err = screenshot(!*fullscreen && !*window && *output == "", *window, *output)
		if err != nil {
			fmt.Fprintf(os.Stderr, "error taking screenshot: %v\n", err)
			os.Exit(1)
		}
	}

	// run OCR
	words, err := runOCR(imgData)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error running OCR: %v\n", err)
		os.Exit(1)
	}

	if len(words) == 0 {
		notify("live-ocr", "no text detected")
		os.Exit(0)
	}

	// auto-copy all detected text to clipboard
	allText := wordsToString(words)
	if copyErr := copyToClipboard(allText); copyErr != nil {
		fmt.Fprintf(os.Stderr, "auto-copy failed: %v\n", copyErr)
	} else {
		notify("live-ocr", fmt.Sprintf("copied %d words to clipboard", len(words)))
	}

	// show overlay for refining selection
	err = showOverlay(imgData, words)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error showing overlay: %v\n", err)
		os.Exit(1)
	}
}
