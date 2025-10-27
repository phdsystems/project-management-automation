package audit

import (
	"context"
	"encoding/json"
	"time"
)

// EventType represents the type of audit event
type EventType string

const (
	EventTypeLogin           EventType = "auth.login"
	EventTypeLogout          EventType = "auth.logout"
	EventTypeTokenRefresh    EventType = "auth.token.refresh"
	EventTypeTokenRevoke     EventType = "auth.token.revoke"
	EventTypeMFAEnroll      EventType = "mfa.enroll"
	EventTypeMFAVerify      EventType = "mfa.verify"
	EventTypeMFADisable     EventType = "mfa.disable"
	EventTypePasswordChange  EventType = "user.password.change"
	EventTypeProfileUpdate   EventType = "user.profile.update"
	EventTypePermissionGrant EventType = "permission.grant"
	EventTypePermissionRevoke EventType = "permission.revoke"
	EventTypeConfigChange    EventType = "config.change"
	EventTypeSecurityAlert   EventType = "security.alert"
	EventTypeRateLimitExceed EventType = "ratelimit.exceed"
	EventTypeSSOLogin        EventType = "sso.login"
)

// Severity represents the severity level of an audit event
type Severity string

const (
	SeverityInfo     Severity = "info"
	SeverityWarning  Severity = "warning"
	SeverityError    Severity = "error"
	SeverityCritical Severity = "critical"
)

// AuditLog represents an audit log entry
type AuditLog struct {
	ID          string                 `json:"id" db:"id"`
	Timestamp   time.Time              `json:"timestamp" db:"timestamp"`
	EventType   EventType              `json:"event_type" db:"event_type"`
	Severity    Severity               `json:"severity" db:"severity"`
	UserID      string                 `json:"user_id,omitempty" db:"user_id"`
	SessionID   string                 `json:"session_id,omitempty" db:"session_id"`
	IP          string                 `json:"ip" db:"ip"`
	UserAgent   string                 `json:"user_agent" db:"user_agent"`
	Resource    string                 `json:"resource,omitempty" db:"resource"`
	Action      string                 `json:"action" db:"action"`
	Result      string                 `json:"result" db:"result"`
	Details     map[string]interface{} `json:"details,omitempty" db:"details"`
	ErrorMsg    string                 `json:"error_msg,omitempty" db:"error_msg"`
	GeoLocation *GeoLocation           `json:"geo_location,omitempty" db:"geo_location"`
}

// GeoLocation represents geographic information
type GeoLocation struct {
	Country   string  `json:"country"`
	City      string  `json:"city"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

// ComplianceReport represents a compliance report
type ComplianceReport struct {
	ID            string    `json:"id"`
	UserID        string    `json:"user_id"`
	RequestedAt   time.Time `json:"requested_at"`
	CompletedAt   time.Time `json:"completed_at"`
	Type          string    `json:"type"` // gdpr, ccpa, etc.
	Status        string    `json:"status"`
	DataExportURL string    `json:"data_export_url,omitempty"`
}

// SecurityAlert represents a security alert
type SecurityAlert struct {
	ID          string    `json:"id"`
	Timestamp   time.Time `json:"timestamp"`
	Type        string    `json:"type"`
	Severity    Severity  `json:"severity"`
	UserID      string    `json:"user_id,omitempty"`
	Description string    `json:"description"`
	Actions     []string  `json:"actions"`
	Resolved    bool      `json:"resolved"`
}

// AuditService defines the interface for audit operations
type AuditService interface {
	// Log creates a new audit log entry
	Log(ctx context.Context, log *AuditLog) error
	
	// Query retrieves audit logs based on filters
	Query(ctx context.Context, filter *AuditFilter) ([]*AuditLog, error)
	
	// GetUserLogs retrieves all logs for a specific user
	GetUserLogs(ctx context.Context, userID string) ([]*AuditLog, error)
	
	// ExportUserData exports all user data for GDPR compliance
	ExportUserData(ctx context.Context, userID string) (*ComplianceReport, error)
	
	// DeleteUserData deletes all user data for GDPR compliance
	DeleteUserData(ctx context.Context, userID string) error
	
	// GenerateComplianceReport generates a compliance report
	GenerateComplianceReport(ctx context.Context, reportType string) (*ComplianceReport, error)
	
	// CreateSecurityAlert creates a new security alert
	CreateSecurityAlert(ctx context.Context, alert *SecurityAlert) error
	
	// GetSecurityAlerts retrieves active security alerts
	GetSecurityAlerts(ctx context.Context) ([]*SecurityAlert, error)
	
	// ResolveSecurityAlert marks an alert as resolved
	ResolveSecurityAlert(ctx context.Context, alertID string) error
}

// AuditFilter represents filters for querying audit logs
type AuditFilter struct {
	StartTime  *time.Time           `json:"start_time,omitempty"`
	EndTime    *time.Time           `json:"end_time,omitempty"`
	UserID     string               `json:"user_id,omitempty"`
	EventTypes []EventType          `json:"event_types,omitempty"`
	Severity   []Severity           `json:"severity,omitempty"`
	IP         string               `json:"ip,omitempty"`
	Resource   string               `json:"resource,omitempty"`
	Limit      int                  `json:"limit,omitempty"`
	Offset     int                  `json:"offset,omitempty"`
}

// AnomalyDetector detects suspicious activity patterns
type AnomalyDetector interface {
	// DetectLoginAnomaly checks for suspicious login patterns
	DetectLoginAnomaly(ctx context.Context, userID string, ip string, location *GeoLocation) bool
	
	// DetectBruteForce checks for brute force attempts
	DetectBruteForce(ctx context.Context, identifier string) bool
	
	// DetectGeoAnomaly checks for geographic anomalies
	DetectGeoAnomaly(ctx context.Context, userID string, location *GeoLocation) bool
	
	// DetectConcurrentSessions checks for unusual concurrent sessions
	DetectConcurrentSessions(ctx context.Context, userID string) bool
}

// ComplianceManager handles compliance-related operations
type ComplianceManager interface {
	// HandleGDPRRequest processes GDPR requests
	HandleGDPRRequest(ctx context.Context, userID string, requestType string) (*ComplianceReport, error)
	
	// HandleCCPARequest processes CCPA requests
	HandleCCPARequest(ctx context.Context, userID string, requestType string) (*ComplianceReport, error)
	
	// ValidateDataRetention validates data retention policies
	ValidateDataRetention(ctx context.Context) error
	
	// PurgeExpiredData removes data past retention period
	PurgeExpiredData(ctx context.Context) error
}

// AuditLogger provides a simple interface for logging audit events
type AuditLogger struct {
	service AuditService
}

// NewAuditLogger creates a new audit logger
func NewAuditLogger(service AuditService) *AuditLogger {
	return &AuditLogger{service: service}
}

// LogLogin logs a login event
func (l *AuditLogger) LogLogin(ctx context.Context, userID, sessionID, ip, userAgent string, success bool) error {
	result := "success"
	severity := SeverityInfo
	if !success {
		result = "failure"
		severity = SeverityWarning
	}
	
	return l.service.Log(ctx, &AuditLog{
		Timestamp: time.Now(),
		EventType: EventTypeLogin,
		Severity:  severity,
		UserID:    userID,
		SessionID: sessionID,
		IP:        ip,
		UserAgent: userAgent,
		Action:    "login",
		Result:    result,
	})
}

// LogMFAEvent logs an MFA-related event
func (l *AuditLogger) LogMFAEvent(ctx context.Context, eventType EventType, userID, ip string, details map[string]interface{}) error {
	return l.service.Log(ctx, &AuditLog{
		Timestamp: time.Now(),
		EventType: eventType,
		Severity:  SeverityInfo,
		UserID:    userID,
		IP:        ip,
		Action:    string(eventType),
		Result:    "success",
		Details:   details,
	})
}

// LogSecurityEvent logs a security event
func (l *AuditLogger) LogSecurityEvent(ctx context.Context, eventType EventType, severity Severity, description string, details map[string]interface{}) error {
	return l.service.Log(ctx, &AuditLog{
		Timestamp: time.Now(),
		EventType: eventType,
		Severity:  severity,
		Action:    "security_event",
		Result:    "detected",
		Details:   details,
		ErrorMsg:  description,
	})
}

// AuditMiddleware provides HTTP middleware for audit logging
type AuditMiddleware struct {
	logger *AuditLogger
}

// NewAuditMiddleware creates new audit middleware
func NewAuditMiddleware(logger *AuditLogger) *AuditMiddleware {
	return &AuditMiddleware{logger: logger}
}

// SerializeDetails converts details to JSON for database storage
func SerializeDetails(details map[string]interface{}) (json.RawMessage, error) {
	if details == nil {
		return nil, nil
	}
	return json.Marshal(details)
}