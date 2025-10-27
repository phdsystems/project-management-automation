package ratelimit

import (
	"context"
	"fmt"
	"net"
	"sync"
	"time"
)

// LimitType represents the type of rate limit
type LimitType string

const (
	LimitTypeGlobal    LimitType = "global"
	LimitTypeIP        LimitType = "ip"
	LimitTypeUser      LimitType = "user"
	LimitTypeEndpoint  LimitType = "endpoint"
	LimitTypeAPIKey    LimitType = "api_key"
)

// Strategy represents the rate limiting strategy
type Strategy string

const (
	StrategyFixedWindow    Strategy = "fixed_window"
	StrategySlidingWindow  Strategy = "sliding_window"
	StrategyTokenBucket    Strategy = "token_bucket"
	StrategyLeakyBucket    Strategy = "leaky_bucket"
	StrategyAdaptive       Strategy = "adaptive"
)

// Action represents the action to take when limit is exceeded
type Action string

const (
	ActionBlock     Action = "block"
	ActionThrottle  Action = "throttle"
	ActionCaptcha   Action = "captcha"
	ActionChallenge Action = "challenge"
	ActionLog       Action = "log"
)

// RateLimit represents a rate limit configuration
type RateLimit struct {
	ID          string        `json:"id" db:"id"`
	Name        string        `json:"name" db:"name"`
	Type        LimitType     `json:"type" db:"type"`
	Strategy    Strategy      `json:"strategy" db:"strategy"`
	Limit       int64         `json:"limit" db:"limit"`
	Window      time.Duration `json:"window" db:"window"`
	BurstSize   int64         `json:"burst_size,omitempty" db:"burst_size"`
	Action      Action        `json:"action" db:"action"`
	Priority    int           `json:"priority" db:"priority"`
	Enabled     bool          `json:"enabled" db:"enabled"`
	Conditions  []Condition   `json:"conditions,omitempty" db:"conditions"`
	Exemptions  []string      `json:"exemptions,omitempty" db:"exemptions"`
	CreatedAt   time.Time     `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time     `json:"updated_at" db:"updated_at"`
}

// Condition represents a condition for applying rate limit
type Condition struct {
	Field    string `json:"field"`
	Operator string `json:"operator"`
	Value    string `json:"value"`
}

// Request represents an incoming request to check
type Request struct {
	ID        string            `json:"id"`
	IP        string            `json:"ip"`
	UserID    string            `json:"user_id,omitempty"`
	APIKey    string            `json:"api_key,omitempty"`
	Endpoint  string            `json:"endpoint"`
	Method    string            `json:"method"`
	Headers   map[string]string `json:"headers"`
	Timestamp time.Time         `json:"timestamp"`
}

// Result represents the result of a rate limit check
type Result struct {
	Allowed       bool          `json:"allowed"`
	Limit         int64         `json:"limit"`
	Remaining     int64         `json:"remaining"`
	ResetAt       time.Time     `json:"reset_at"`
	RetryAfter    time.Duration `json:"retry_after,omitempty"`
	Action        Action        `json:"action,omitempty"`
	Reason        string        `json:"reason,omitempty"`
	ChallengeData interface{}   `json:"challenge_data,omitempty"`
}

// RateLimiter defines the interface for rate limiting operations
type RateLimiter interface {
	// Check checks if a request is allowed
	Check(ctx context.Context, req *Request) (*Result, error)
	
	// Reset resets the rate limit for an identifier
	Reset(ctx context.Context, limitType LimitType, identifier string) error
	
	// GetStatus gets the current status for an identifier
	GetStatus(ctx context.Context, limitType LimitType, identifier string) (*Status, error)
	
	// Block temporarily blocks an identifier
	Block(ctx context.Context, identifier string, duration time.Duration, reason string) error
	
	// Unblock removes a block on an identifier
	Unblock(ctx context.Context, identifier string) error
	
	// IsBlocked checks if an identifier is blocked
	IsBlocked(ctx context.Context, identifier string) (bool, *BlockInfo, error)
}

// Status represents the current rate limit status
type Status struct {
	Identifier string        `json:"identifier"`
	Type       LimitType     `json:"type"`
	Current    int64         `json:"current"`
	Limit      int64         `json:"limit"`
	Remaining  int64         `json:"remaining"`
	Window     time.Duration `json:"window"`
	ResetAt    time.Time     `json:"reset_at"`
}

// BlockInfo represents information about a blocked identifier
type BlockInfo struct {
	Identifier  string    `json:"identifier"`
	BlockedAt   time.Time `json:"blocked_at"`
	UnblockedAt time.Time `json:"unblocked_at"`
	Reason      string    `json:"reason"`
	Permanent   bool      `json:"permanent"`
}

// ConfigService manages rate limit configurations
type ConfigService interface {
	// CreateLimit creates a new rate limit
	CreateLimit(ctx context.Context, limit *RateLimit) error
	
	// UpdateLimit updates an existing rate limit
	UpdateLimit(ctx context.Context, limit *RateLimit) error
	
	// GetLimit retrieves a rate limit by ID
	GetLimit(ctx context.Context, id string) (*RateLimit, error)
	
	// ListLimits lists all rate limits
	ListLimits(ctx context.Context) ([]*RateLimit, error)
	
	// DeleteLimit deletes a rate limit
	DeleteLimit(ctx context.Context, id string) error
	
	// GetApplicableLimits gets limits that apply to a request
	GetApplicableLimits(ctx context.Context, req *Request) ([]*RateLimit, error)
}

// Store defines the interface for rate limit storage
type Store interface {
	// Increment increments the counter for an identifier
	Increment(ctx context.Context, key string, window time.Duration) (int64, error)
	
	// Get gets the current count for an identifier
	Get(ctx context.Context, key string) (int64, error)
	
	// Set sets the count for an identifier
	Set(ctx context.Context, key string, value int64, expiration time.Duration) error
	
	// Delete deletes the counter for an identifier
	Delete(ctx context.Context, key string) error
	
	// GetWithTimestamp gets count with timestamp
	GetWithTimestamp(ctx context.Context, key string) (int64, time.Time, error)
	
	// AddToSlidingWindow adds an entry to sliding window
	AddToSlidingWindow(ctx context.Context, key string, timestamp time.Time) error
	
	// CountInWindow counts entries in sliding window
	CountInWindow(ctx context.Context, key string, window time.Duration) (int64, error)
}

// DDoSProtector handles DDoS protection
type DDoSProtector interface {
	// DetectAttack detects if a DDoS attack is occurring
	DetectAttack(ctx context.Context) (bool, *AttackInfo, error)
	
	// EnableProtection enables DDoS protection mode
	EnableProtection(ctx context.Context, level ProtectionLevel) error
	
	// DisableProtection disables DDoS protection mode
	DisableProtection(ctx context.Context) error
	
	// GetProtectionStatus gets current protection status
	GetProtectionStatus(ctx context.Context) (*ProtectionStatus, error)
	
	// AddToBlacklist adds an IP to the blacklist
	AddToBlacklist(ctx context.Context, ip string, duration time.Duration) error
	
	// RemoveFromBlacklist removes an IP from the blacklist
	RemoveFromBlacklist(ctx context.Context, ip string) error
	
	// GetBlacklist gets the current blacklist
	GetBlacklist(ctx context.Context) ([]string, error)
}

// AttackInfo represents information about a detected attack
type AttackInfo struct {
	Detected      bool      `json:"detected"`
	Type          string    `json:"type"`
	Severity      string    `json:"severity"`
	StartedAt     time.Time `json:"started_at"`
	SourceIPs     []string  `json:"source_ips"`
	RequestRate   float64   `json:"request_rate"`
	AffectedPaths []string  `json:"affected_paths"`
}

// ProtectionLevel represents the level of DDoS protection
type ProtectionLevel string

const (
	ProtectionLevelLow      ProtectionLevel = "low"
	ProtectionLevelMedium   ProtectionLevel = "medium"
	ProtectionLevelHigh     ProtectionLevel = "high"
	ProtectionLevelCritical ProtectionLevel = "critical"
)

// ProtectionStatus represents the current protection status
type ProtectionStatus struct {
	Enabled       bool            `json:"enabled"`
	Level         ProtectionLevel `json:"level"`
	ActiveSince   *time.Time      `json:"active_since,omitempty"`
	BlockedIPs    int             `json:"blocked_ips"`
	RequestsDropped int64         `json:"requests_dropped"`
	Challenges    int64           `json:"challenges_issued"`
}

// AdaptiveLimiter implements adaptive rate limiting
type AdaptiveLimiter struct {
	baseLimit     int64
	currentLimit  int64
	window        time.Duration
	mu            sync.RWMutex
	metrics       *Metrics
	lastAdjusted  time.Time
}

// NewAdaptiveLimiter creates a new adaptive limiter
func NewAdaptiveLimiter(baseLimit int64, window time.Duration) *AdaptiveLimiter {
	return &AdaptiveLimiter{
		baseLimit:    baseLimit,
		currentLimit: baseLimit,
		window:       window,
		metrics:      &Metrics{},
		lastAdjusted: time.Now(),
	}
}

// AdjustLimit adjusts the limit based on current metrics
func (a *AdaptiveLimiter) AdjustLimit(ctx context.Context) {
	a.mu.Lock()
	defer a.mu.Unlock()
	
	now := time.Now()
	if now.Sub(a.lastAdjusted) < time.Minute {
		return
	}
	
	// Calculate adjustment based on metrics
	errorRate := a.metrics.GetErrorRate()
	responseTime := a.metrics.GetAverageResponseTime()
	
	if errorRate > 0.05 || responseTime > 1*time.Second {
		// Decrease limit
		a.currentLimit = int64(float64(a.currentLimit) * 0.9)
		if a.currentLimit < a.baseLimit/2 {
			a.currentLimit = a.baseLimit / 2
		}
	} else if errorRate < 0.01 && responseTime < 200*time.Millisecond {
		// Increase limit
		a.currentLimit = int64(float64(a.currentLimit) * 1.1)
		if a.currentLimit > a.baseLimit*2 {
			a.currentLimit = a.baseLimit * 2
		}
	}
	
	a.lastAdjusted = now
}

// GetCurrentLimit returns the current adaptive limit
func (a *AdaptiveLimiter) GetCurrentLimit() int64 {
	a.mu.RLock()
	defer a.mu.RUnlock()
	return a.currentLimit
}

// Metrics tracks rate limiting metrics
type Metrics struct {
	TotalRequests    int64
	AllowedRequests  int64
	BlockedRequests  int64
	Errors           int64
	TotalResponseTime time.Duration
	mu               sync.RWMutex
}

// GetErrorRate calculates the error rate
func (m *Metrics) GetErrorRate() float64 {
	m.mu.RLock()
	defer m.mu.RUnlock()
	
	if m.TotalRequests == 0 {
		return 0
	}
	return float64(m.Errors) / float64(m.TotalRequests)
}

// GetAverageResponseTime calculates average response time
func (m *Metrics) GetAverageResponseTime() time.Duration {
	m.mu.RLock()
	defer m.mu.RUnlock()
	
	if m.AllowedRequests == 0 {
		return 0
	}
	return m.TotalResponseTime / time.Duration(m.AllowedRequests)
}

// Challenge represents a challenge for suspicious requests
type Challenge interface {
	// Generate generates a new challenge
	Generate(ctx context.Context) (interface{}, error)
	
	// Verify verifies a challenge response
	Verify(ctx context.Context, challenge, response interface{}) (bool, error)
	
	// GetType returns the challenge type
	GetType() string
}

// CaptchaChallenge implements CAPTCHA challenge
type CaptchaChallenge struct {
	provider string
	siteKey  string
	secret   string
}

// ProofOfWorkChallenge implements proof-of-work challenge
type ProofOfWorkChallenge struct {
	difficulty int
	timeout    time.Duration
}

// IPWhitelist manages IP whitelisting
type IPWhitelist struct {
	ranges []*net.IPNet
	ips    map[string]bool
	mu     sync.RWMutex
}

// NewIPWhitelist creates a new IP whitelist
func NewIPWhitelist() *IPWhitelist {
	return &IPWhitelist{
		ips: make(map[string]bool),
	}
}

// AddIP adds an IP to the whitelist
func (w *IPWhitelist) AddIP(ip string) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	
	parsedIP := net.ParseIP(ip)
	if parsedIP == nil {
		return fmt.Errorf("invalid IP address: %s", ip)
	}
	
	w.ips[ip] = true
	return nil
}

// AddCIDR adds a CIDR range to the whitelist
func (w *IPWhitelist) AddCIDR(cidr string) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	
	_, ipNet, err := net.ParseCIDR(cidr)
	if err != nil {
		return fmt.Errorf("invalid CIDR: %w", err)
	}
	
	w.ranges = append(w.ranges, ipNet)
	return nil
}

// IsWhitelisted checks if an IP is whitelisted
func (w *IPWhitelist) IsWhitelisted(ip string) bool {
	w.mu.RLock()
	defer w.mu.RUnlock()
	
	if w.ips[ip] {
		return true
	}
	
	parsedIP := net.ParseIP(ip)
	if parsedIP == nil {
		return false
	}
	
	for _, ipNet := range w.ranges {
		if ipNet.Contains(parsedIP) {
			return true
		}
	}
	
	return false
}

// RateLimitMiddleware provides HTTP middleware for rate limiting
type RateLimitMiddleware struct {
	limiter   RateLimiter
	whitelist *IPWhitelist
}

// NewRateLimitMiddleware creates new rate limit middleware
func NewRateLimitMiddleware(limiter RateLimiter, whitelist *IPWhitelist) *RateLimitMiddleware {
	return &RateLimitMiddleware{
		limiter:   limiter,
		whitelist: whitelist,
	}
}

// GenerateKey generates a rate limit key
func GenerateKey(limitType LimitType, identifier string) string {
	return fmt.Sprintf("ratelimit:%s:%s", limitType, identifier)
}

// ExtractIP extracts the real IP from request headers
func ExtractIP(headers map[string]string) string {
	// Check X-Forwarded-For
	if xff := headers["X-Forwarded-For"]; xff != "" {
		ips := strings.Split(xff, ",")
		if len(ips) > 0 {
			return strings.TrimSpace(ips[0])
		}
	}
	
	// Check X-Real-IP
	if xri := headers["X-Real-IP"]; xri != "" {
		return xri
	}
	
	// Check CF-Connecting-IP (Cloudflare)
	if cfIP := headers["CF-Connecting-IP"]; cfIP != "" {
		return cfIP
	}
	
	return headers["Remote-Addr"]
}