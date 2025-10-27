package events_test

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	events "goat/internal/events"
)

func TestDefaultWebhookDelivererAsyncDeliveryE2E(t *testing.T) {
	t.Parallel()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	var (
		mu        sync.Mutex
		signature string
		custom    string
		hits      int64
	)

	deliverer := events.NewDefaultWebhookDeliverer(1)
	setDelivererClient(deliverer, &http.Client{
		Transport: roundTripperFunc(func(req *http.Request) (*http.Response, error) {
			atomic.AddInt64(&hits, 1)
			mu.Lock()
			signature = req.Header.Get("X-Webhook-Signature")
			custom = req.Header.Get("X-Custom-Header")
			mu.Unlock()
			return &http.Response{
				Status:     fmt.Sprintf("%d %s", http.StatusOK, http.StatusText(http.StatusOK)),
				StatusCode: http.StatusOK,
				Body:       io.NopCloser(strings.NewReader("{\"status\":\"ok\"}")),
				Header:     make(http.Header),
			}, nil
		}),
	})
	setDelivererRetryDelay(deliverer, time.Millisecond)

	deliverer.Start(ctx)
	defer deliverer.Stop()

	event := &events.Event{
		ID:        "event-async",
		Type:      events.EventUserLogin,
		Priority:  events.PriorityHigh,
		Timestamp: time.Now().UTC().Round(0),
	}
	webhook := &events.Webhook{
		ID:      "webhook-async",
		URL:     "https://e2e.example/webhook",
		Secret:  "async-secret",
		Headers: map[string]string{"X-Custom-Header": "custom-value"},
	}

	delivery, err := deliverer.Deliver(context.Background(), webhook, event)
	if err != nil {
		t.Fatalf("deliver returned error: %v", err)
	}
	if delivery == nil {
		t.Fatalf("expected delivery details, got nil")
	}
	if !delivery.Success {
		t.Fatalf("expected delivery to succeed")
	}
	if delivery.Attempts != 1 {
		t.Fatalf("expected attempts to be 1, got %d", delivery.Attempts)
	}
	if delivery.DeliveredAt == nil {
		t.Fatalf("expected delivered at timestamp to be set")
	}
	if delivery.Headers["Content-Type"] != "application/json" {
		t.Fatalf("expected content-type header to be recorded, got %q", delivery.Headers["Content-Type"])
	}
	if delivery.Headers["X-Custom-Header"] != "custom-value" {
		t.Fatalf("expected custom header to be recorded, got %q", delivery.Headers["X-Custom-Header"])
	}

	mu.Lock()
	gotSignature := signature
	gotCustom := custom
	mu.Unlock()

	if gotCustom != "custom-value" {
		t.Fatalf("expected webhook to forward custom header, got %q", gotCustom)
	}

	payload, err := json.Marshal(event)
	if err != nil {
		t.Fatalf("failed to marshal event: %v", err)
	}
	hasher := hmac.New(sha256.New, []byte(webhook.Secret))
	hasher.Write(payload)
	wantSignature := "sha256=" + hex.EncodeToString(hasher.Sum(nil))
	if gotSignature != wantSignature {
		t.Fatalf("unexpected signature header: got %q, want %q", gotSignature, wantSignature)
	}

	if atomic.LoadInt64(&hits) != 1 {
		t.Fatalf("expected exactly one request, got %d", atomic.LoadInt64(&hits))
	}
}
