package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
)

// screenshot captures the screen using grim (and slurp for region/window selection)
func screenshot(region bool, window bool, output string) ([]byte, error) {
	args := []string{}

	if window {
		// get focused window geometry from niri or sway
		geometry, err := focusedWindowGeometry()
		if err != nil {
			return nil, fmt.Errorf("get window geometry: %w", err)
		}
		args = append(args, "-g", geometry)
	} else if region {
		// use slurp to select region
		slurpCmd := exec.Command("slurp")
		slurpOut, err := slurpCmd.Output()
		if err != nil {
			return nil, fmt.Errorf("slurp failed (cancelled?): %w", err)
		}
		geometry := strings.TrimSpace(string(slurpOut))
		args = append(args, "-g", geometry)
	} else if output != "" {
		args = append(args, "-o", output)
	}

	// output to stdout as png
	args = append(args, "-")

	cmd := exec.Command("grim", args...)
	data, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("grim failed: %w", err)
	}

	return data, nil
}

// focusedWindowGeometry returns the geometry of the focused window as "X,Y WxH"
func focusedWindowGeometry() (string, error) {
	// try niri first
	geometry, err := niriWindowGeometry()
	if err == nil {
		return geometry, nil
	}

	// try swaymsg
	geometry, err = swayWindowGeometry()
	if err == nil {
		return geometry, nil
	}

	// fallback to slurp in window mode
	cmd := exec.Command("slurp")
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("no supported compositor found and slurp failed: %w", err)
	}
	return strings.TrimSpace(string(out)), nil
}

func niriWindowGeometry() (string, error) {
	cmd := exec.Command("niri", "msg", "-j", "focused-window")
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}

	var win struct {
		X      int `json:"x"`
		Y      int `json:"y"`
		Width  int `json:"width"`
		Height int `json:"height"`
	}
	if err := json.Unmarshal(out, &win); err != nil {
		return "", err
	}

	return fmt.Sprintf("%d,%d %dx%d", win.X, win.Y, win.Width, win.Height), nil
}

func swayWindowGeometry() (string, error) {
	cmd := exec.Command("swaymsg", "-t", "get_tree")
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}

	// find focused window in sway tree
	var tree map[string]interface{}
	if err := json.Unmarshal(out, &tree); err != nil {
		return "", err
	}

	rect := findFocusedRect(tree)
	if rect == nil {
		return "", fmt.Errorf("no focused window found")
	}

	x := int(rect["x"].(float64))
	y := int(rect["y"].(float64))
	w := int(rect["width"].(float64))
	h := int(rect["height"].(float64))

	return fmt.Sprintf("%d,%d %dx%d", x, y, w, h), nil
}

func findFocusedRect(node map[string]interface{}) map[string]interface{} {
	if focused, ok := node["focused"].(bool); ok && focused {
		if rect, ok := node["rect"].(map[string]interface{}); ok {
			return rect
		}
	}

	if nodes, ok := node["nodes"].([]interface{}); ok {
		for _, n := range nodes {
			if m, ok := n.(map[string]interface{}); ok {
				if r := findFocusedRect(m); r != nil {
					return r
				}
			}
		}
	}

	if nodes, ok := node["floating_nodes"].([]interface{}); ok {
		for _, n := range nodes {
			if m, ok := n.(map[string]interface{}); ok {
				if r := findFocusedRect(m); r != nil {
					return r
				}
			}
		}
	}

	return nil
}
