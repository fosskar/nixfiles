package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

const (
	source = "herdr-jj"
	token  = "jj_bookmark"
)

type pane struct {
	WorkspaceID string `json:"workspace_id"`
	Cwd         string `json:"cwd"`
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "herdr-jj:", err)
		os.Exit(1)
	}
}

func run() error {
	herdr := os.Getenv("HERDR_BIN_PATH")
	if herdr == "" {
		herdr = "herdr"
	}

	out, err := exec.Command(herdr, "pane", "list").Output()
	if err != nil {
		return fmt.Errorf("herdr pane list: %w", err)
	}
	var list struct {
		Result struct {
			Panes []pane `json:"panes"`
		} `json:"result"`
	}
	if err := json.Unmarshal(out, &list); err != nil {
		return fmt.Errorf("parse herdr pane list: %w", err)
	}

	// event hooks refresh the workspace that fired the event; startup refreshes all
	only := ""
	if os.Getenv("HERDR_PLUGIN_EVENT") != "startup" {
		only = os.Getenv("HERDR_WORKSPACE_ID")
	}

	cwds := map[string]string{}
	var order []string
	for _, p := range list.Result.Panes {
		if p.Cwd == "" || (only != "" && p.WorkspaceID != only) {
			continue
		}
		if _, seen := cwds[p.WorkspaceID]; !seen {
			cwds[p.WorkspaceID] = p.Cwd
			order = append(order, p.WorkspaceID)
		}
	}

	var failed []string
	for _, ws := range order {
		// a hook that read the repo later carries a higher seq, so an older
		// concurrent hook cannot overwrite its report
		seq := strconv.FormatInt(time.Now().UnixNano(), 10)
		args := []string{"workspace", "report-metadata", ws, "--source", source, "--seq", seq}
		label, err := bookmarkLabel(cwds[ws])
		if err != nil {
			fmt.Fprintf(os.Stderr, "herdr-jj: %s (%s): %v\n", ws, cwds[ws], err)
		}
		if label == "" {
			args = append(args, "--clear-token", token)
		} else {
			args = append(args, "--token", token+"="+label)
		}
		if out, err := exec.Command(herdr, args...).CombinedOutput(); err != nil {
			failed = append(failed, fmt.Sprintf("%s: %v: %s", ws, err, bytes.TrimSpace(out)))
		}
	}
	if len(failed) > 0 {
		return fmt.Errorf("report-metadata failed: %s", strings.Join(failed, "; "))
	}
	return nil
}

// bookmarkLabel returns "" outside a jj repo, the nearest bookmark below @
// with its distance ("main+2"), or the short change id of @ without one.
func bookmarkLabel(dir string) (string, error) {
	if _, err := jj(dir, "root"); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			return "", nil
		}
		return "", err
	}

	name, err := jj(dir, "log", "--no-graph", "--limit", "1",
		"-r", "heads(::@ & bookmarks())",
		"-T", `local_bookmarks.map(|b| b.name()).join(",")`)
	if err != nil {
		return "", err
	}
	if name == "" {
		return jj(dir, "log", "--no-graph", "-r", "@", "-T", "change_id.shortest(8)")
	}
	name, _, _ = strings.Cut(name, ",")

	// an empty, undescribed @ is the usual scratch change on top of finished
	// work and does not count towards the distance
	ahead, err := jj(dir, "log", "--no-graph",
		"-r", `heads(::@ & bookmarks())..@ ~ (@ & empty() & description(exact:""))`,
		"-T", `"x"`)
	if err != nil {
		return "", err
	}
	if len(ahead) == 0 {
		return name, nil
	}
	return fmt.Sprintf("%s+%d", name, len(ahead)), nil
}

// --ignore-working-copy keeps the hook read-only: it never snapshots files
// an agent is still writing
func jj(dir string, args ...string) (string, error) {
	cmd := exec.Command("jj", append([]string{"--ignore-working-copy", "--color=never", "--no-pager"}, args...)...)
	cmd.Dir = dir
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("jj %s: %w: %s", strings.Join(args, " "), err, bytes.TrimSpace(stderr.Bytes()))
	}
	return strings.TrimSpace(string(out)), nil
}
