package main

import (
	"context"
	"slices"
	"testing"

	gateway "github.com/cs3org/go-cs3apis/cs3/gateway/v1beta1"
	rpc "github.com/cs3org/go-cs3apis/cs3/rpc/v1beta1"
	provider "github.com/cs3org/go-cs3apis/cs3/storage/provider/v1beta1"
	"google.golang.org/grpc"
)

type fakeGateway struct {
	gateway.GatewayAPIClient
	dirs map[string][]*provider.ResourceInfo
}

func (f fakeGateway) ListContainer(_ context.Context, req *provider.ListContainerRequest, _ ...grpc.CallOption) (*provider.ListContainerResponse, error) {
	infos, ok := f.dirs[req.GetRef().GetResourceId().GetOpaqueId()]
	if !ok || req.GetRef().GetPath() != "." {
		return &provider.ListContainerResponse{Status: &rpc.Status{Code: rpc.Code_CODE_NOT_FOUND}}, nil
	}
	return &provider.ListContainerResponse{Status: &rpc.Status{Code: rpc.Code_CODE_OK}, Infos: infos}, nil
}

func info(id, name string, t provider.ResourceType) *provider.ResourceInfo {
	return &provider.ResourceInfo{Id: &provider.ResourceId{OpaqueId: id}, Path: name, Type: t}
}

func TestWalk(t *testing.T) {
	file, dir := provider.ResourceType_RESOURCE_TYPE_FILE, provider.ResourceType_RESOURCE_TYPE_CONTAINER
	gwc := fakeGateway{dirs: map[string][]*provider.ResourceInfo{
		"root":   {info("a", "a.pdf", file), info("sub", "sub", dir)},
		"sub":    {info("b", "b.PDF", file), info("deeper", "deeper", dir)},
		"deeper": {info("c", "c.txt", file)},
	}}
	var got []string
	err := walk(context.Background(), gwc, &provider.ResourceId{OpaqueId: "root"}, func(i *provider.ResourceInfo) {
		got = append(got, i.GetId().GetOpaqueId())
	})
	if err != nil {
		t.Fatal(err)
	}
	slices.Sort(got)
	if !slices.Equal(got, []string{"a", "b", "c"}) {
		t.Fatalf("walked files %v", got)
	}

	gwc.dirs["sub"] = append(gwc.dirs["sub"], info("missing", "missing", dir))
	if err := walk(context.Background(), gwc, &provider.ResourceId{OpaqueId: "root"}, func(*provider.ResourceInfo) {}); err == nil {
		t.Fatal("expected an error for a folder that cannot be listed")
	}
}
