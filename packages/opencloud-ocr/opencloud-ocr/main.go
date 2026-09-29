// opencloud-ocr adds a text layer to scanned pdfs uploaded to opencloud. it
// reads UploadReady events from the main-queue jetstream stream, runs
// ocrmypdf on each pdf without text and uploads the result as a new version
// through the reva gateway as the opencloud service account.
package main

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	gateway "github.com/cs3org/go-cs3apis/cs3/gateway/v1beta1"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

const (
	natsAddress    = "nats://127.0.0.1:9233"
	gatewayAddress = "127.0.0.1:9142"
	languages      = "deu+eng"
	stream         = "main-queue"
	consumerName   = "opencloud-ocr"
	maxDeliver     = 5
)

func main() {
	if err := run(); err != nil {
		slog.Error("exiting", "error", err)
		os.Exit(1)
	}
}

func run() error {
	credentials := os.Getenv("CREDENTIALS_DIRECTORY")
	if credentials == "" {
		return errors.New("CREDENTIALS_DIRECTORY is not set")
	}
	id, secret, err := readServiceAccount(filepath.Join(credentials, "envfile"))
	if err != nil {
		return err
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	conn, err := grpc.NewClient(gatewayAddress, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return err
	}
	defer conn.Close()
	p := &processor{
		gwc:              gateway.NewGatewayAPIClient(conn),
		serviceAccountID: id,
		serviceSecret:    secret,
		languages:        languages,
	}

	if len(os.Args) > 1 {
		if os.Args[1] != "backfill" {
			return fmt.Errorf("unknown command %q", os.Args[1])
		}
		return backfill(ctx, p)
	}

	nc, err := nats.Connect(natsAddress, nats.Name(consumerName), nats.MaxReconnects(-1))
	if err != nil {
		return err
	}
	defer nc.Close()
	js, err := jetstream.New(nc)
	if err != nil {
		return err
	}
	// a durable consumer keeps its position while the service is down; new
	// starts at the first event after its creation, not at the stream's
	// seven days of history
	cons, err := js.CreateOrUpdateConsumer(ctx, stream, jetstream.ConsumerConfig{
		Durable:       consumerName,
		DeliverPolicy: jetstream.DeliverNewPolicy,
		AckPolicy:     jetstream.AckExplicitPolicy,
		AckWait:       5 * time.Minute,
		MaxDeliver:    maxDeliver,
		MaxAckPending: 20,
	})
	if err != nil {
		return fmt.Errorf("consumer %s on %s: %w", consumerName, stream, err)
	}
	// events waiting for a retry count against MaxAckPending, so it is above
	// one to keep a failing file from blocking the queue. fetching one event
	// at a time keeps buffered events from timing out during a long ocr run.
	msgs, err := cons.Messages(jetstream.PullMaxMessages(1))
	if err != nil {
		return err
	}
	go func() {
		<-ctx.Done()
		msgs.Stop()
	}()
	slog.Info("consuming", "stream", stream, "consumer", consumerName, "gateway", gatewayAddress, "languages", languages)

	for {
		msg, err := msgs.Next()
		if errors.Is(err, jetstream.ErrMsgIteratorClosed) {
			return nil
		}
		if err != nil {
			return err
		}
		handle(ctx, p, msg)
	}
}

func handle(ctx context.Context, p *processor, msg jetstream.Msg) {
	ev, err := parseUploadReady(msg.Data())
	if err != nil {
		slog.Warn("undecodable event", "error", err)
	}
	if ev == nil {
		ack(msg)
		return
	}
	log := slog.With("upload", ev.UploadID, "file", ev.Filename)
	if reason := skipReason(ev, p.serviceAccountID); reason != "" {
		if reason != reasonNotPDF {
			log.Info("skipped", "reason", reason)
		}
		ack(msg)
		return
	}

	done := make(chan struct{})
	go func() {
		t := time.NewTicker(time.Minute)
		defer t.Stop()
		for {
			select {
			case <-done:
				return
			case <-t.C:
				if err := msg.InProgress(); err != nil {
					log.Warn("extending ack deadline", "error", err)
				}
			}
		}
	}()
	err = p.process(ctx, ev, log)
	close(done)

	var permanent permanentError
	switch {
	case err == nil:
		ack(msg)
	case errors.As(err, &permanent):
		log.Error("failed", "error", err)
		ack(msg)
	default:
		delivered := uint64(0)
		if md, mdErr := msg.Metadata(); mdErr == nil {
			delivered = md.NumDelivered
		}
		if delivered >= maxDeliver {
			log.Error("failed, giving up", "error", err, "attempt", delivered)
			ack(msg)
			return
		}
		log.Warn("failed, will retry", "error", err, "attempt", delivered)
		if err := msg.NakWithDelay(time.Minute); err != nil {
			log.Warn("nak", "error", err)
		}
	}
}

func ack(msg jetstream.Msg) {
	if err := msg.Ack(); err != nil {
		slog.Warn("ack", "error", err)
	}
}

func readServiceAccount(path string) (string, string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", "", err
	}
	defer f.Close()
	var id, secret string
	s := bufio.NewScanner(f)
	for s.Scan() {
		k, v, _ := strings.Cut(s.Text(), "=")
		switch k {
		case "OC_SERVICE_ACCOUNT_ID":
			id = v
		case "OC_SERVICE_ACCOUNT_SECRET":
			secret = v
		}
	}
	if err := s.Err(); err != nil {
		return "", "", err
	}
	if id == "" || secret == "" {
		return "", "", fmt.Errorf("%s: OC_SERVICE_ACCOUNT_ID or OC_SERVICE_ACCOUNT_SECRET missing", path)
	}
	return id, secret, nil
}
