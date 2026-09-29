package main

import (
	"context"
	"fmt"
	"log/slog"
	"path"
	"strings"

	gateway "github.com/cs3org/go-cs3apis/cs3/gateway/v1beta1"
	rpc "github.com/cs3org/go-cs3apis/cs3/rpc/v1beta1"
	provider "github.com/cs3org/go-cs3apis/cs3/storage/provider/v1beta1"
	types "github.com/cs3org/go-cs3apis/cs3/types/v1beta1"
)

// backfill processes every pdf that already exists in a personal or project
// space, the same way as an uploaded one. it lists spaces unrestricted, which
// the service account role allows through Drives.List. all pdfs are listed
// before the first is processed, so the listing token cannot expire midway.
func backfill(ctx context.Context, p *processor) error {
	listCtx, _, err := p.authenticate(ctx)
	if err != nil {
		return err
	}
	res, err := p.gwc.ListStorageSpaces(listCtx, &provider.ListStorageSpacesRequest{
		Opaque: &types.Opaque{Map: map[string]*types.OpaqueEntry{
			"unrestricted": {Decoder: "plain", Value: []byte("true")},
		}},
		Filters: []*provider.ListStorageSpacesRequest_Filter{
			{Type: provider.ListStorageSpacesRequest_Filter_TYPE_SPACE_TYPE, Term: &provider.ListStorageSpacesRequest_Filter_SpaceType{SpaceType: "personal"}},
			{Type: provider.ListStorageSpacesRequest_Filter_TYPE_SPACE_TYPE, Term: &provider.ListStorageSpacesRequest_Filter_SpaceType{SpaceType: "project"}},
		},
	})
	if err != nil {
		return fmt.Errorf("list spaces: %w", err)
	}
	if res.GetStatus().GetCode() != rpc.Code_CODE_OK {
		return fmt.Errorf("list spaces: %s %s", res.GetStatus().GetCode(), res.GetStatus().GetMessage())
	}

	type job struct {
		space string
		ev    *uploadReady
	}
	var jobs []job
	failed := 0
	for _, space := range res.GetStorageSpaces() {
		err := walk(listCtx, p.gwc, space.GetRoot(), func(info *provider.ResourceInfo) {
			name := path.Base(info.GetPath())
			if strings.EqualFold(path.Ext(name), ".pdf") {
				jobs = append(jobs, job{space.GetName(), &uploadReady{Filename: name, FileRef: &provider.Reference{ResourceId: info.GetId(), Path: "."}}})
			}
		})
		if err != nil {
			failed++
			slog.Error("listing space", "space", space.GetName(), "error", err)
		}
	}
	slog.Info("backfill listed", "spaces", len(res.GetStorageSpaces()), "pdfs", len(jobs))

	for i, j := range jobs {
		if ctx.Err() != nil {
			return ctx.Err()
		}
		log := slog.With("space", j.space, "file", j.ev.Filename, "n", fmt.Sprintf("%d/%d", i+1, len(jobs)))
		if err := p.process(ctx, j.ev, log); err != nil {
			failed++
			log.Error("failed", "error", err)
		}
	}
	slog.Info("backfill done", "pdfs", len(jobs), "failed", failed)
	if failed > 0 {
		return fmt.Errorf("%d failures", failed)
	}
	return nil
}

// walk calls fn for every file below root. a folder that cannot be listed
// stops the walk of that space.
func walk(ctx context.Context, gwc gateway.GatewayAPIClient, root *provider.ResourceId, fn func(*provider.ResourceInfo)) error {
	dirs := []*provider.ResourceId{root}
	for len(dirs) > 0 {
		if ctx.Err() != nil {
			return ctx.Err()
		}
		dir := dirs[len(dirs)-1]
		dirs = dirs[:len(dirs)-1]
		res, err := gwc.ListContainer(ctx, &provider.ListContainerRequest{Ref: &provider.Reference{ResourceId: dir, Path: "."}})
		if err != nil {
			return fmt.Errorf("list container: %w", err)
		}
		if res.GetStatus().GetCode() != rpc.Code_CODE_OK {
			return fmt.Errorf("list container: %s %s", res.GetStatus().GetCode(), res.GetStatus().GetMessage())
		}
		for _, info := range res.GetInfos() {
			switch info.GetType() {
			case provider.ResourceType_RESOURCE_TYPE_CONTAINER:
				dirs = append(dirs, info.GetId())
			case provider.ResourceType_RESOURCE_TYPE_FILE:
				fn(info)
			}
		}
	}
	return nil
}
