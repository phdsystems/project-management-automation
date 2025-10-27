package events_test

import (
	"net/http"
	"reflect"
	"time"
	"unsafe"

	events "goat/internal/events"
)

type roundTripperFunc func(*http.Request) (*http.Response, error)

func (f roundTripperFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

func setDelivererClient(deliverer *events.DefaultWebhookDeliverer, client *http.Client) {
	v := reflect.ValueOf(deliverer).Elem().FieldByName("client")
	reflect.NewAt(v.Type(), unsafe.Pointer(v.UnsafeAddr())).Elem().Set(reflect.ValueOf(client))
}

func setDelivererRetryDelay(deliverer *events.DefaultWebhookDeliverer, delay time.Duration) {
	v := reflect.ValueOf(deliverer).Elem().FieldByName("retryDelay")
	reflect.NewAt(v.Type(), unsafe.Pointer(v.UnsafeAddr())).Elem().Set(reflect.ValueOf(delay))
}
