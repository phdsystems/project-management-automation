package events_test

import (
	"context"
	"testing"

	events "goat/internal/events"
)

func TestDefaultWebhookDelivererNilInputTest(t *testing.T) {
	t.Parallel()

	deliverer := events.NewDefaultWebhookDeliverer(1)

	if _, err := deliverer.Deliver(context.Background(), nil, &events.Event{}); err == nil {
		t.Fatalf("expected error when webhook is nil")
	}

	if _, err := deliverer.Deliver(context.Background(), &events.Webhook{}, nil); err == nil {
		t.Fatalf("expected error when event is nil")
	}
}
