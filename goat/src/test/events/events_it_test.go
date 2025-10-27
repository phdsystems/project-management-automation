package events_test

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	events "goat/internal/events"
)

func TestDefaultWebhookDelivererRetryDeliveryIT(t *testing.T) {
	t.Parallel()

	ctx := context.Background()

	var hits int64
	deliverer := events.NewDefaultWebhookDeliverer(0)
	setDelivererClient(deliverer, &http.Client{
		Transport: roundTripperFunc(func(req *http.Request) (*http.Response, error) {
			attempt := atomic.AddInt64(&hits, 1)
			body := "ok"
			status := http.StatusOK
			if attempt == 1 {
				body = "fail"
				status = http.StatusInternalServerError
			}
			return &http.Response{
				Status:     fmt.Sprintf("%d %s", status, http.StatusText(status)),
				StatusCode: status,
				Body:       io.NopCloser(strings.NewReader(body)),
				Header:     make(http.Header),
			}, nil
		}),
	})
	setDelivererRetryDelay(deliverer, time.Millisecond)

	event := &events.Event{
		ID:        "event-retry",
		Type:      events.EventUserLogin,
		Priority:  events.PriorityHigh,
		Timestamp: time.Now(),
	}
	webhook := &events.Webhook{
		ID:  "webhook-retry",
		URL: "https://retry.example/webhook",
	}

	delivery, err := deliverer.Deliver(ctx, webhook, event)
	if err == nil {
		t.Fatalf("expected initial delivery error, got nil")
	}
	if delivery == nil {
		t.Fatalf("expected delivery details, got nil")
	}
	if delivery.Success {
		t.Fatalf("expected delivery to fail on first attempt")
	}
	if delivery.NextRetryAt == nil {
		t.Fatalf("expected next retry time after failure")
	}
	if delivery.ID == "" {
		t.Fatalf("expected delivery id to be assigned")
	}

	retried, err := deliverer.RetryDelivery(ctx, delivery.ID)
	if err != nil {
		t.Fatalf("retry delivery returned error: %v", err)
	}
	if retried == nil {
		t.Fatalf("expected retried delivery details, got nil")
	}
	if !retried.Success {
		t.Fatalf("expected retry to succeed")
	}
	if retried.Attempts != 2 {
		t.Fatalf("expected attempts to be 2, got %d", retried.Attempts)
	}
	if retried.StatusCode != http.StatusOK {
		t.Fatalf("expected status 200, got %d", retried.StatusCode)
	}
	if retried.NextRetryAt != nil {
		t.Fatalf("expected next retry time to be cleared after success")
	}
	if retried.Response != "ok" {
		t.Fatalf("expected response body 'ok', got %q", retried.Response)
	}
	if retried.ID == delivery.ID {
		t.Fatalf("expected new delivery id after retry, but got same id %q", retried.ID)
	}
	if atomic.LoadInt64(&hits) != 2 {
		t.Fatalf("expected handler to be called twice, got %d", atomic.LoadInt64(&hits))
	}
}
