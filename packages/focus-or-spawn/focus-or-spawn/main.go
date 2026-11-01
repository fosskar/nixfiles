// focus-or-spawn focuses a window by exact app id, or spawns the command and
// focuses the new window. Supports niri and umbriel over their IPC sockets.
//
// Usage: focus-or-spawn <app_id> <command...>
//
// Forked from https://github.com/piv-pav/niri-focus-or-spawn (public domain).
package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type window struct {
	id    string
	appID string
}

type compositor interface {
	windows() ([]window, error)
	focus(id string) error
	spawn(command []string) error
}

// request writes one JSON line and reads one JSON line back; both compositors
// use this framing.
func request(socketPath string, req any) ([]byte, error) {
	conn, err := net.Dial("unix", socketPath)
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	body, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("marshal request: %w", err)
	}
	if _, err := conn.Write(append(body, '\n')); err != nil {
		return nil, fmt.Errorf("write request: %w", err)
	}
	conn.(*net.UnixConn).CloseWrite()

	scanner := bufio.NewScanner(conn)
	scanner.Buffer(make([]byte, 0, 1024*1024), 16*1024*1024)
	if !scanner.Scan() {
		if err := scanner.Err(); err != nil {
			return nil, fmt.Errorf("read reply: %w", err)
		}
		return nil, errors.New("empty reply")
	}
	return scanner.Bytes(), nil
}

// --- niri ---

type niri struct{ socket string }

func (n niri) call(req any) (json.RawMessage, error) {
	line, err := request(n.socket, req)
	if err != nil {
		return nil, err
	}
	var reply struct {
		Ok  json.RawMessage `json:"Ok"`
		Err *string         `json:"Err"`
	}
	if err := json.Unmarshal(line, &reply); err != nil {
		return nil, fmt.Errorf("unmarshal niri reply: %w", err)
	}
	if reply.Err != nil {
		return nil, fmt.Errorf("niri: %s", *reply.Err)
	}
	return reply.Ok, nil
}

func (n niri) windows() ([]window, error) {
	raw, err := n.call(map[string]any{"Windows": nil})
	if err != nil {
		return nil, err
	}
	var resp struct {
		Windows []struct {
			ID    uint64  `json:"id"`
			AppID *string `json:"app_id"`
		} `json:"Windows"`
	}
	if err := json.Unmarshal(raw, &resp); err != nil {
		return nil, fmt.Errorf("unmarshal niri windows: %w", err)
	}
	out := make([]window, 0, len(resp.Windows))
	for _, w := range resp.Windows {
		if w.AppID != nil {
			out = append(out, window{id: fmt.Sprint(w.ID), appID: *w.AppID})
		}
	}
	return out, nil
}

func (n niri) focus(id string) error {
	var numeric uint64
	if _, err := fmt.Sscan(id, &numeric); err != nil {
		return fmt.Errorf("niri window id %q: %w", id, err)
	}
	_, err := n.call(map[string]any{"Action": map[string]any{"FocusWindow": map[string]any{"id": numeric}}})
	return err
}

func (n niri) spawn(command []string) error {
	_, err := n.call(map[string]any{"Action": map[string]any{"Spawn": map[string]any{"command": command}}})
	return err
}

// --- umbriel ---

type umbriel struct{ socket string }

func (u umbriel) call(req any) (json.RawMessage, error) {
	line, err := request(u.socket, req)
	if err != nil {
		return nil, err
	}
	var reply struct {
		Ok  json.RawMessage `json:"ok"`
		Err *string         `json:"err"`
	}
	if err := json.Unmarshal(line, &reply); err != nil {
		return nil, fmt.Errorf("unmarshal umbriel reply: %w", err)
	}
	if reply.Err != nil {
		return nil, fmt.Errorf("umbriel: %s", *reply.Err)
	}
	return reply.Ok, nil
}

func (u umbriel) windows() ([]window, error) {
	raw, err := u.call(map[string]any{"cmd": "windows"})
	if err != nil {
		return nil, err
	}
	var entries []struct {
		ID    string `json:"id"`
		AppID string `json:"app_id"`
	}
	if err := json.Unmarshal(raw, &entries); err != nil {
		return nil, fmt.Errorf("unmarshal umbriel windows: %w", err)
	}
	out := make([]window, 0, len(entries))
	for _, w := range entries {
		out = append(out, window{id: w.ID, appID: w.AppID})
	}
	return out, nil
}

func (u umbriel) focus(id string) error {
	_, err := u.call(map[string]any{"cmd": "action", "action": "window-focus", "window": id})
	return err
}

// umbriel's spawn takes one shell command line, so quote each argument.
func (u umbriel) spawn(command []string) error {
	quoted := make([]string, len(command))
	for i, arg := range command {
		quoted[i] = "'" + strings.ReplaceAll(arg, "'", `'\''`) + "'"
	}
	_, err := u.call(map[string]any{"cmd": "action", "action": "spawn", "command": strings.Join(quoted, " ")})
	return err
}

// --- detection ---

// connectable rejects stale socket paths: after switching sessions the systemd
// user environment can still name the previous compositor's socket.
func connectable(path string) bool {
	if path == "" {
		return false
	}
	conn, err := net.Dial("unix", path)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}

func detect() (compositor, error) {
	umbrielSocket := os.Getenv("UMBRIEL_SOCKET")
	if umbrielSocket == "" && os.Getenv("XDG_RUNTIME_DIR") != "" && os.Getenv("WAYLAND_DISPLAY") != "" {
		umbrielSocket = filepath.Join(os.Getenv("XDG_RUNTIME_DIR"), "umbriel-"+os.Getenv("WAYLAND_DISPLAY")+".sock")
	}
	if connectable(umbrielSocket) {
		return umbriel{umbrielSocket}, nil
	}
	if niriSocket := os.Getenv("NIRI_SOCKET"); connectable(niriSocket) {
		return niri{niriSocket}, nil
	}
	return nil, errors.New("no running niri or umbriel found (checked UMBRIEL_SOCKET, XDG_RUNTIME_DIR/umbriel-WAYLAND_DISPLAY.sock, NIRI_SOCKET)")
}

func find(windows []window, appID string) *window {
	for i := range windows {
		if windows[i].appID == appID {
			return &windows[i]
		}
	}
	return nil
}

func main() {
	if len(os.Args) < 3 {
		fmt.Fprintf(os.Stderr, "usage: %s <app_id> <command...>\n", filepath.Base(os.Args[0]))
		os.Exit(2)
	}
	appID, command := os.Args[1], os.Args[2:]

	c, err := detect()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	windows, err := c.windows()
	if err != nil {
		fmt.Fprintf(os.Stderr, "list windows: %v\n", err)
		os.Exit(1)
	}
	if w := find(windows, appID); w != nil {
		if err := c.focus(w.id); err != nil {
			fmt.Fprintf(os.Stderr, "focus window: %v\n", err)
			os.Exit(1)
		}
		return
	}

	if err := c.spawn(command); err != nil {
		fmt.Fprintf(os.Stderr, "spawn: %v\n", err)
		os.Exit(1)
	}

	// poll up to 2.5s for the new window, then focus it
	for range 50 {
		if windows, err := c.windows(); err == nil {
			if w := find(windows, appID); w != nil {
				_ = c.focus(w.id)
				return
			}
		}
		time.Sleep(50 * time.Millisecond)
	}
}
