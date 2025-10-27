package events

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"
)

// EventType represents the type of event
type EventType string

const (
	// Authentication Events
	EventUserLogin           EventType = "user.login"
	EventUserLogout          EventType = "user.logout"
	EventUserLoginFailed     EventType = "user.login.failed"
	EventTokenCreated        EventType = "token.created"
	EventTokenRefreshed      EventType = "token.refreshed"
	EventTokenRevoked        EventType = "token.revoked"
	EventTokenExpired        EventType = "token.expired"
	
	// MFA Events
	EventMFAEnabled          EventType = "mfa.enabled"
	EventMFADisabled         EventType = "mfa.disabled"
	EventMFAVerified         EventType = "mfa.verified"
	EventMFAFailed           EventType = "mfa.failed"
	EventMFADeviceAdded      EventType = "mfa.device.added"
	EventMFADeviceRemoved    EventType = "mfa.device.removed"
	
	// User Management Events
	EventUserCreated         EventType = "user.created"
	EventUserUpdated         EventType = "user.updated"
	EventUserDeleted         EventType = "user.deleted"
	EventUserPasswordChanged EventType = "user.password.changed"
	EventUserEmailVerified   EventType = "user.email.verified"
	
	// Permission Events
	EventRoleCreated         EventType = "role.created"
	EventRoleUpdated         EventType = "role.updated"
	EventRoleDeleted         EventType = "role.deleted"
	EventPermissionGranted   EventType = "permission.granted"
	EventPermissionRevoked   EventType = "permission.revoked"
	
	// Security Events
	EventSecurityAlert       EventType = "security.alert"
	EventSuspiciousActivity  EventType = "security.suspicious"
	EventBruteForceDetected  EventType = "security.bruteforce"
	EventRateLimitExceeded   EventType = "security.ratelimit"
	EventIPBlocked           EventType = "security.ip.blocked"
	
	// System Events
	EventSystemStarted       EventType = "system.started"
	EventSystemStopped       EventType = "system.stopped"
	EventConfigChanged       EventType = "system.config.changed"
	EventKeyRotated          EventType = "system.key.rotated"
	EventBackupCompleted     EventType = "system.backup.completed"
	
	// SSO Events
	EventSSOLogin            EventType = "sso.login"
	EventSSOLogout           EventType = "sso.logout"
	EventSSOProviderAdded    EventType = "sso.provider.added"
	EventSSOProviderRemoved  EventType = "sso.provider.removed"
)

// Priority represents event priority
type Priority string

const (
	PriorityLow      Priority = "low"
	PriorityNormal   Priority = "normal"
	PriorityHigh     Priority = "high"
	PriorityCritical Priority = "critical"
)

// Event represents a system event
type Event struct {
	ID          string                 `json:"id" db:"id"`
	Type        EventType              `json:"type" db:"type"`
	Priority    Priority               `json:"priority" db:"priority"`
	Timestamp   time.Time              `json:"timestamp" db:"timestamp"`
	UserID      string                 `json:"user_id,omitempty" db:"user_id"`
	SessionID   string                 `json:"session_id,omitempty" db:"session_id"`
	IP          string                 `json:"ip,omitempty" db:"ip"`
	UserAgent   string                 `json:"user_agent,omitempty" db:"user_agent"`
	Resource    string                 `json:"resource,omitempty" db:"resource"`
	Action      string                 `json:"action,omitempty" db:"action"`
	Result      string                 `json:"result,omitempty" db:"result"`
	Data        map[string]interface{} `json:"data,omitempty" db:"data"`
	Metadata    map[string]interface{} `json:"metadata,omitempty" db:"metadata"`
}

// Webhook represents a webhook configuration
type Webhook struct {
	ID          string            `json:"id" db:"id"`
	Name        string            `json:"name" db:"name"`
	URL         string            `json:"url" db:"url"`
	Events      []EventType       `json:"events" db:"events"`
	Headers     map[string]string `json:"headers,omitempty" db:"headers"`
	Secret      string            `json:"-" db:"secret"` // For HMAC signing
	Active      bool              `json:"active" db:"active"`
	RetryConfig *RetryConfig      `json:"retry_config,omitempty" db:"retry_config"`
	Filters     []Filter          `json:"filters,omitempty" db:"filters"`
	CreatedAt   time.Time         `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at" db:"updated_at"`
	LastTriggered *time.Time      `json:"last_triggered,omitempty" db:"last_triggered"`
	FailureCount int              `json:"failure_count" db:"failure_count"`
}

// RetryConfig represents webhook retry configuration
type RetryConfig struct {
	MaxRetries     int           `json:"max_retries"`
	InitialDelay   time.Duration `json:"initial_delay"`
	MaxDelay       time.Duration `json:"max_delay"`
	Multiplier     float64       `json:"multiplier"`
	Timeout        time.Duration `json:"timeout"`
}

// Filter represents an event filter
type Filter struct {
	Field    string      `json:"field"`
	Operator string      `json:"operator"`
	Value    interface{} `json:"value"`
}

// Subscription represents an event subscription
type Subscription struct {
	ID          string            `json:"id" db:"id"`
	Name        string            `json:"name" db:"name"`
	Type        string            `json:"type" db:"type"` // webhook, stream, queue
	Events      []EventType       `json:"events" db:"events"`
	Destination string            `json:"destination" db:"destination"`
	Config      map[string]interface{} `json:"config,omitempty" db:"config"`
	Filters     []Filter          `json:"filters,omitempty" db:"filters"`
	Active      bool              `json:"active" db:"active"`
	CreatedAt   time.Time         `json:"created_at" db:"created_at"`
}

// EventService defines the interface for event operations
type EventService interface {
	// Publish publishes an event
	Publish(ctx context.Context, event *Event) error
	
	// Subscribe creates a subscription to events
	Subscribe(ctx context.Context, subscription *Subscription) error
	
	// Unsubscribe removes a subscription
	Unsubscribe(ctx context.Context, subscriptionID string) error
	
	// GetEvents retrieves events based on filters
	GetEvents(ctx context.Context, filter *EventFilter) ([]*Event, error)
	
	// GetEvent retrieves a specific event
	GetEvent(ctx context.Context, eventID string) (*Event, error)
	
	// Stream streams events in real-time
	Stream(ctx context.Context, filter *EventFilter) (<-chan *Event, error)
}

// WebhookService defines the interface for webhook operations
type WebhookService interface {
	// CreateWebhook creates a new webhook
	CreateWebhook(ctx context.Context, webhook *Webhook) error
	
	// UpdateWebhook updates an existing webhook
	UpdateWebhook(ctx context.Context, webhook *Webhook) error
	
	// GetWebhook retrieves a webhook by ID
	GetWebhook(ctx context.Context, webhookID string) (*Webhook, error)
	
	// ListWebhooks lists all webhooks
	ListWebhooks(ctx context.Context) ([]*Webhook, error)
	
	// DeleteWebhook deletes a webhook
	DeleteWebhook(ctx context.Context, webhookID string) error
	
	// TestWebhook tests a webhook with sample data
	TestWebhook(ctx context.Context, webhookID string) (*WebhookTestResult, error)
	
	// GetDeliveryHistory gets webhook delivery history
	GetDeliveryHistory(ctx context.Context, webhookID string) ([]*Delivery, error)
}

// EventFilter represents filters for querying events
type EventFilter struct {
	Types      []EventType            `json:"types,omitempty"`
	Priority   []Priority             `json:"priority,omitempty"`
	StartTime  *time.Time             `json:"start_time,omitempty"`
	EndTime    *time.Time             `json:"end_time,omitempty"`
	UserID     string                 `json:"user_id,omitempty"`
	SessionID  string                 `json:"session_id,omitempty"`
	Resource   string                 `json:"resource,omitempty"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
	Limit      int                    `json:"limit,omitempty"`
	Offset     int                    `json:"offset,omitempty"`
}

// Delivery represents a webhook delivery attempt
type Delivery struct {
	ID           string        `json:"id" db:"id"`
	WebhookID    string        `json:"webhook_id" db:"webhook_id"`
	EventID      string        `json:"event_id" db:"event_id"`
	URL          string        `json:"url" db:"url"`
	Method       string        `json:"method" db:"method"`
	Headers      map[string]string `json:"headers" db:"headers"`
	Payload      json.RawMessage `json:"payload" db:"payload"`
	Response     string        `json:"response,omitempty" db:"response"`
	StatusCode   int           `json:"status_code" db:"status_code"`
	Success      bool          `json:"success" db:"success"`
	Error        string        `json:"error,omitempty" db:"error"`
	Attempts     int           `json:"attempts" db:"attempts"`
	DeliveredAt  *time.Time    `json:"delivered_at,omitempty" db:"delivered_at"`
	NextRetryAt  *time.Time    `json:"next_retry_at,omitempty" db:"next_retry_at"`
	CreatedAt    time.Time     `json:"created_at" db:"created_at"`
}

// WebhookTestResult represents the result of a webhook test
type WebhookTestResult struct {
	Success      bool              `json:"success"`
	StatusCode   int               `json:"status_code"`
	ResponseTime time.Duration     `json:"response_time"`
	Headers      map[string]string `json:"headers"`
	Body         string            `json:"body"`
	Error        string            `json:"error,omitempty"`
}

// EventBus handles event distribution
type EventBus interface {
	// Publish publishes an event to the bus
	Publish(ctx context.Context, event *Event) error
	
	// Subscribe subscribes to events
	Subscribe(ctx context.Context, types []EventType, handler EventHandler) (string, error)
	
	// Unsubscribe removes a subscription
	Unsubscribe(ctx context.Context, subscriptionID string) error
	
	// Start starts the event bus
	Start(ctx context.Context) error
	
	// Stop stops the event bus
	Stop(ctx context.Context) error
}

// EventHandler handles events
type EventHandler func(ctx context.Context, event *Event) error

// WebhookDeliverer handles webhook delivery
type WebhookDeliverer interface {
	// Deliver delivers an event to a webhook
	Deliver(ctx context.Context, webhook *Webhook, event *Event) (*Delivery, error)
	
	// RetryDelivery retries a failed delivery
	RetryDelivery(ctx context.Context, deliveryID string) (*Delivery, error)
	
	// ProcessQueue processes the delivery queue
	ProcessQueue(ctx context.Context) error
}

// StreamingService handles event streaming
type StreamingService interface {
	// StreamSSE streams events via Server-Sent Events
	StreamSSE(ctx context.Context, w http.ResponseWriter, filter *EventFilter) error
	
	// StreamWebSocket streams events via WebSocket
	StreamWebSocket(ctx context.Context, conn interface{}, filter *EventFilter) error
	
	// PublishToKafka publishes events to Kafka
	PublishToKafka(ctx context.Context, event *Event) error
	
	// PublishToNATS publishes events to NATS
	PublishToNATS(ctx context.Context, event *Event) error
	
	// PublishToEventBridge publishes events to AWS EventBridge
	PublishToEventBridge(ctx context.Context, event *Event) error
}

// EventProcessor processes events
type EventProcessor interface {
	// Process processes an event
	Process(ctx context.Context, event *Event) error
	
	// Transform transforms an event
	Transform(ctx context.Context, event *Event, rules []TransformRule) (*Event, error)
	
	// Filter filters an event
	Filter(ctx context.Context, event *Event, filters []Filter) (bool, error)
	
	// Enrich enriches an event with additional data
	Enrich(ctx context.Context, event *Event) (*Event, error)
}

// TransformRule represents an event transformation rule
type TransformRule struct {
	Type      string                 `json:"type"`
	Field     string                 `json:"field"`
	Operation string                 `json:"operation"`
	Value     interface{}            `json:"value,omitempty"`
	Config    map[string]interface{} `json:"config,omitempty"`
}

// DefaultWebhookDeliverer implements webhook delivery
type DefaultWebhookDeliverer struct {
	client      *http.Client
	maxRetries  int
	retryDelay  time.Duration
	queue       chan *DeliveryTask
	workers     int
	wg          sync.WaitGroup
}

// DeliveryTask represents a webhook delivery task
type DeliveryTask struct {
	Webhook  *Webhook
	Event    *Event
	Attempt  int
	Callback chan *Delivery
}

// NewDefaultWebhookDeliverer creates a new webhook deliverer
func NewDefaultWebhookDeliverer(workers int) *DefaultWebhookDeliverer {
	return &DefaultWebhookDeliverer{
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
		maxRetries: 3,
		retryDelay: 1 * time.Second,
		queue:      make(chan *DeliveryTask, 1000),
		workers:    workers,
	}
}

// Start starts the webhook deliverer workers
func (d *DefaultWebhookDeliverer) Start(ctx context.Context) {
	for i := 0; i < d.workers; i++ {
		d.wg.Add(1)
		go d.worker(ctx)
	}
}

// Stop stops the webhook deliverer
func (d *DefaultWebhookDeliverer) Stop() {
	close(d.queue)
	d.wg.Wait()
}

// worker processes delivery tasks
func (d *DefaultWebhookDeliverer) worker(ctx context.Context) {
	defer d.wg.Done()
	
	for task := range d.queue {
		select {
		case <-ctx.Done():
			return
		default:
			delivery := d.deliver(ctx, task)
			if task.Callback != nil {
				task.Callback <- delivery
			}
		}
	}
}

// deliver performs the actual webhook delivery
func (d *DefaultWebhookDeliverer) deliver(ctx context.Context, task *DeliveryTask) *Delivery {
	payload, err := json.Marshal(task.Event)
	if err != nil {
		return &Delivery{
			WebhookID: task.Webhook.ID,
			EventID:   task.Event.ID,
			Success:   false,
			Error:     err.Error(),
		}
	}
	
	req, err := http.NewRequestWithContext(ctx, "POST", task.Webhook.URL, bytes.NewReader(payload))
	if err != nil {
		return &Delivery{
			WebhookID: task.Webhook.ID,
			EventID:   task.Event.ID,
			Success:   false,
			Error:     err.Error(),
		}
	}
	
	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Webhook-ID", task.Webhook.ID)
	req.Header.Set("X-Event-ID", task.Event.ID)
	req.Header.Set("X-Event-Type", string(task.Event.Type))
	
	// Add custom headers
	for key, value := range task.Webhook.Headers {
		req.Header.Set(key, value)
	}
	
	// Add HMAC signature if secret is configured
	if task.Webhook.Secret != "" {
		signature := d.generateSignature(payload, task.Webhook.Secret)
		req.Header.Set("X-Webhook-Signature", signature)
	}
	
	// Send request
	resp, err := d.client.Do(req)
	if err != nil {
		return &Delivery{
			WebhookID: task.Webhook.ID,
			EventID:   task.Event.ID,
			Success:   false,
			Error:     err.Error(),
			Attempts:  task.Attempt,
		}
	}
	defer resp.Body.Close()
	
	// Read response
	body := make([]byte, 1024)
	n, _ := resp.Body.Read(body)
	
	delivery := &Delivery{
		WebhookID:   task.Webhook.ID,
		EventID:     task.Event.ID,
		URL:         task.Webhook.URL,
		Method:      "POST",
		Payload:     payload,
		Response:    string(body[:n]),
		StatusCode:  resp.StatusCode,
		Success:     resp.StatusCode >= 200 && resp.StatusCode < 300,
		Attempts:    task.Attempt,
		DeliveredAt: &time.Time{},
	}
	*delivery.DeliveredAt = time.Now()
	
	return delivery
}

// generateSignature generates HMAC-SHA256 signature
func (d *DefaultWebhookDeliverer) generateSignature(payload []byte, secret string) string {
	h := hmac.New(sha256.New, []byte(secret))
	h.Write(payload)
	return "sha256=" + hex.EncodeToString(h.Sum(nil))
}

// EventRouter routes events to appropriate handlers
type EventRouter struct {
	routes map[EventType][]EventHandler
	mu     sync.RWMutex
}

// NewEventRouter creates a new event router
func NewEventRouter() *EventRouter {
	return &EventRouter{
		routes: make(map[EventType][]EventHandler),
	}
}

// Register registers a handler for an event type
func (r *EventRouter) Register(eventType EventType, handler EventHandler) {
	r.mu.Lock()
	defer r.mu.Unlock()
	
	r.routes[eventType] = append(r.routes[eventType], handler)
}

// Route routes an event to registered handlers
func (r *EventRouter) Route(ctx context.Context, event *Event) error {
	r.mu.RLock()
	handlers := r.routes[event.Type]
	r.mu.RUnlock()
	
	var errs []error
	for _, handler := range handlers {
		if err := handler(ctx, event); err != nil {
			errs = append(errs, err)
		}
	}
	
	if len(errs) > 0 {
		return fmt.Errorf("handler errors: %v", errs)
	}
	
	return nil
}

// DeadLetterQueue handles failed deliveries
type DeadLetterQueue interface {
	// Add adds a failed delivery to the queue
	Add(ctx context.Context, delivery *Delivery) error
	
	// Get retrieves failed deliveries
	Get(ctx context.Context, limit int) ([]*Delivery, error)
	
	// Retry retries a failed delivery
	Retry(ctx context.Context, deliveryID string) error
	
	// Delete removes a delivery from the queue
	Delete(ctx context.Context, deliveryID string) error
}

// EventAggregator aggregates events
type EventAggregator interface {
	// Aggregate aggregates events over a time window
	Aggregate(ctx context.Context, window time.Duration) (*AggregatedEvents, error)
	
	// GetStatistics gets event statistics
	GetStatistics(ctx context.Context, filter *EventFilter) (*EventStatistics, error)
}

// AggregatedEvents represents aggregated events
type AggregatedEvents struct {
	Window    time.Duration           `json:"window"`
	StartTime time.Time               `json:"start_time"`
	EndTime   time.Time               `json:"end_time"`
	Total     int64                   `json:"total"`
	ByType    map[EventType]int64     `json:"by_type"`
	ByUser    map[string]int64        `json:"by_user"`
	Trends    []Trend                 `json:"trends"`
}

// EventStatistics represents event statistics
type EventStatistics struct {
	TotalEvents      int64                 `json:"total_events"`
	UniqueUsers      int64                 `json:"unique_users"`
	EventsPerSecond  float64               `json:"events_per_second"`
	TopEventTypes    []EventTypeCount      `json:"top_event_types"`
	TopUsers         []UserEventCount      `json:"top_users"`
	ErrorRate        float64               `json:"error_rate"`
}

// Trend represents an event trend
type Trend struct {
	Timestamp time.Time `json:"timestamp"`
	Count     int64     `json:"count"`
}

// EventTypeCount represents event count by type
type EventTypeCount struct {
	Type  EventType `json:"type"`
	Count int64     `json:"count"`
}

// UserEventCount represents event count by user
type UserEventCount struct {
	UserID string `json:"user_id"`
	Count  int64  `json:"count"`
}