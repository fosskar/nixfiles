package main

import (
	"encoding/json"
	"path"
	"strings"

	provider "github.com/cs3org/go-cs3apis/cs3/storage/provider/v1beta1"
)

// envelope is the go-micro event every opencloud service publishes on
// main-queue; the reva event type is in Metadata["eventtype"].
type envelope struct {
	Metadata map[string]string
	Payload  []byte
}

// uploadReady holds the fields of reva's events.UploadReady this service reads.
type uploadReady struct {
	UploadID      string
	Filename      string
	Failed        bool
	ExecutingUser *struct {
		ID *struct {
			OpaqueID string `json:"opaque_id"`
		} `json:"id"`
	}
	FileRef *provider.Reference
}

func parseUploadReady(data []byte) (*uploadReady, error) {
	var env envelope
	if err := json.Unmarshal(data, &env); err != nil {
		return nil, err
	}
	if env.Metadata["eventtype"] != "events.UploadReady" {
		return nil, nil
	}
	var ev uploadReady
	if err := json.Unmarshal(env.Payload, &ev); err != nil {
		return nil, err
	}
	return &ev, nil
}

const reasonNotPDF = "not a pdf"

// skipReason returns why an upload is not processed, or "" to process it.
// events from the posix watcher carry no executing user and events from this
// service's own uploads carry the service account id; the user type is not
// part of the event.
func skipReason(ev *uploadReady, serviceAccountID string) string {
	switch {
	case ev.Failed:
		return "upload failed"
	case !strings.EqualFold(path.Ext(ev.Filename), ".pdf"):
		return reasonNotPDF
	case ev.ExecutingUser == nil || ev.ExecutingUser.ID == nil || ev.ExecutingUser.ID.OpaqueID == "":
		return "no executing user"
	case ev.ExecutingUser.ID.OpaqueID == serviceAccountID:
		return "own upload"
	case ev.FileRef == nil || ev.FileRef.GetResourceId() == nil:
		return "no file reference"
	}
	return ""
}
