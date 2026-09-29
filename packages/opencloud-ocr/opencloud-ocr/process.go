package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"strconv"

	gateway "github.com/cs3org/go-cs3apis/cs3/gateway/v1beta1"
	rpc "github.com/cs3org/go-cs3apis/cs3/rpc/v1beta1"
	provider "github.com/cs3org/go-cs3apis/cs3/storage/provider/v1beta1"
	types "github.com/cs3org/go-cs3apis/cs3/types/v1beta1"
	"google.golang.org/grpc/metadata"
)

// permanentError marks a failure that a redelivery of the event cannot fix.
type permanentError struct{ error }

type processor struct {
	gwc              gateway.GatewayAPIClient
	serviceAccountID string
	serviceSecret    string
	languages        string
}

// process replaces the pdf the event names with an ocr'd pdf/a version. the
// upload is conditional on the etag read before the download, so a change by
// a user in the meantime wins and the job is dropped.
func (p *processor) process(ctx context.Context, ev *uploadReady, log *slog.Logger) error {
	ctx, token, err := p.authenticate(ctx)
	if err != nil {
		return err
	}

	st, err := p.gwc.Stat(ctx, &provider.StatRequest{Ref: ev.FileRef})
	if err != nil {
		return fmt.Errorf("stat: %w", err)
	}
	switch st.GetStatus().GetCode() {
	case rpc.Code_CODE_OK:
	case rpc.Code_CODE_NOT_FOUND:
		log.Info("skipped", "reason", "file no longer exists")
		return nil
	default:
		return fmt.Errorf("stat: %s %s", st.GetStatus().GetCode(), st.GetStatus().GetMessage())
	}
	info := st.GetInfo()
	if info.GetType() != provider.ResourceType_RESOURCE_TYPE_FILE {
		log.Info("skipped", "reason", "not a file")
		return nil
	}
	// the id survives a rename or move while ocrmypdf runs, the path does not
	ref := &provider.Reference{ResourceId: info.GetId(), Path: "."}
	etag := info.GetEtag()

	dir, err := os.MkdirTemp("", "opencloud-ocr-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(dir)
	src := filepath.Join(dir, "in.pdf")
	dst := filepath.Join(dir, "out.pdf")

	if err := p.download(ctx, token, ref, src); err != nil {
		return err
	}
	done, err := processedByOCRmyPDF(src)
	if err != nil {
		return err
	}
	if done {
		log.Info("skipped", "reason", "already processed by ocrmypdf")
		return nil
	}
	skip, err := ocr(ctx, p.languages, src, dst)
	if err != nil {
		return permanentError{err}
	}
	if skip != "" {
		log.Info("skipped", "reason", skip)
		return nil
	}

	skip, err = p.upload(ctx, token, ref, etag, dst)
	if err != nil {
		return err
	}
	if skip != "" {
		log.Info("skipped", "reason", skip)
		return nil
	}
	out, err := os.Stat(dst)
	if err != nil {
		return err
	}
	log.Info("replaced with ocr version", "size_before", info.GetSize(), "size_after", out.Size())
	return nil
}

func (p *processor) authenticate(ctx context.Context) (context.Context, string, error) {
	auth, err := p.gwc.Authenticate(ctx, &gateway.AuthenticateRequest{
		Type:         "serviceaccounts",
		ClientId:     p.serviceAccountID,
		ClientSecret: p.serviceSecret,
	})
	if err != nil {
		return nil, "", fmt.Errorf("authenticate: %w", err)
	}
	if auth.GetStatus().GetCode() != rpc.Code_CODE_OK {
		return nil, "", fmt.Errorf("authenticate: %s %s", auth.GetStatus().GetCode(), auth.GetStatus().GetMessage())
	}
	token := auth.GetToken()
	return metadata.AppendToOutgoingContext(ctx, "x-access-token", token), token, nil
}

func (p *processor) download(ctx context.Context, token string, ref *provider.Reference, dst string) error {
	res, err := p.gwc.InitiateFileDownload(ctx, &provider.InitiateFileDownloadRequest{Ref: ref})
	if err != nil {
		return fmt.Errorf("initiate download: %w", err)
	}
	if res.GetStatus().GetCode() != rpc.Code_CODE_OK {
		return fmt.Errorf("initiate download: %s %s", res.GetStatus().GetCode(), res.GetStatus().GetMessage())
	}
	var endpoint, transfer string
	for _, proto := range res.GetProtocols() {
		if proto.GetProtocol() == "simple" || proto.GetProtocol() == "spaces" {
			endpoint, transfer = proto.GetDownloadEndpoint(), proto.GetToken()
			break
		}
	}
	if endpoint == "" {
		return errors.New("initiate download: no simple or spaces protocol")
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return err
	}
	req.Header.Set("X-Reva-Transfer", transfer)
	req.Header.Set("X-Access-Token", token)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return fmt.Errorf("download: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("download: %s", resp.Status)
	}
	f, err := os.Create(dst)
	if err != nil {
		return err
	}
	if _, err := io.Copy(f, resp.Body); err != nil {
		f.Close()
		return fmt.Errorf("download: %w", err)
	}
	return f.Close()
}

// upload returns a skip reason when the storage refuses the new version for
// a reason a retry cannot change.
func (p *processor) upload(ctx context.Context, token string, ref *provider.Reference, etag, src string) (string, error) {
	f, err := os.Open(src)
	if err != nil {
		return "", err
	}
	defer f.Close()
	fi, err := f.Stat()
	if err != nil {
		return "", err
	}

	res, err := p.gwc.InitiateFileUpload(ctx, &provider.InitiateFileUploadRequest{
		Ref: ref,
		Opaque: &types.Opaque{Map: map[string]*types.OpaqueEntry{
			"Upload-Length": {Decoder: "plain", Value: []byte(strconv.FormatInt(fi.Size(), 10))},
		}},
		Options: &provider.InitiateFileUploadRequest_IfMatch{IfMatch: etag},
	})
	if err != nil {
		return "", fmt.Errorf("initiate upload: %w", err)
	}
	switch res.GetStatus().GetCode() {
	case rpc.Code_CODE_OK:
	case rpc.Code_CODE_ABORTED, rpc.Code_CODE_FAILED_PRECONDITION:
		return "changed since download", nil
	case rpc.Code_CODE_LOCKED:
		return "locked", nil
	case rpc.Code_CODE_NOT_FOUND:
		return "file no longer exists", nil
	case rpc.Code_CODE_INSUFFICIENT_STORAGE:
		return "quota exceeded", nil
	default:
		return "", fmt.Errorf("initiate upload: %s %s", res.GetStatus().GetCode(), res.GetStatus().GetMessage())
	}
	var endpoint, transfer string
	for _, proto := range res.GetProtocols() {
		if proto.GetProtocol() == "simple" || proto.GetProtocol() == "spaces" {
			endpoint, transfer = proto.GetUploadEndpoint(), proto.GetToken()
			break
		}
	}
	if endpoint == "" {
		return "", errors.New("initiate upload: no simple or spaces protocol")
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPut, endpoint, f)
	if err != nil {
		return "", err
	}
	req.ContentLength = fi.Size()
	req.Header.Set("X-Reva-Transfer", transfer)
	req.Header.Set("X-Access-Token", token)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("upload: %w", err)
	}
	defer resp.Body.Close()
	switch {
	case resp.StatusCode/100 == 2:
		return "", nil
	case resp.StatusCode == http.StatusPreconditionFailed || resp.StatusCode == http.StatusConflict:
		return "changed since download", nil
	}
	body, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
	return "", fmt.Errorf("upload: %s %s", resp.Status, body)
}
