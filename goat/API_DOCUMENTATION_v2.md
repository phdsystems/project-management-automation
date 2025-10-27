# GOAT v2.0 API Documentation

## Overview
GOAT v2.0 provides comprehensive authentication, authorization, and security APIs. All endpoints require authentication unless otherwise specified.

## Base URL
```
https://api.goat.example.com/v2
```

## Authentication
Include the JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

## Response Format
All responses follow this structure:
```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "metadata": {
    "timestamp": "2024-01-01T00:00:00Z",
    "request_id": "uuid"
  }
}
```

---

## 1. Audit & Compliance APIs

### GET /api/audit/logs
Retrieve audit logs with filtering options.

**Query Parameters:**
- `start_time` (ISO 8601): Start of time range
- `end_time` (ISO 8601): End of time range
- `user_id` (UUID): Filter by user
- `event_types` (array): Filter by event types
- `severity` (array): Filter by severity levels
- `limit` (integer): Max results (default: 100)
- `offset` (integer): Pagination offset

**Response:**
```json
{
  "logs": [
    {
      "id": "uuid",
      "timestamp": "2024-01-01T00:00:00Z",
      "event_type": "user.login",
      "severity": "info",
      "user_id": "uuid",
      "ip": "192.168.1.1",
      "action": "login",
      "result": "success"
    }
  ],
  "total": 1000,
  "has_more": true
}
```

### GET /api/audit/logs/{userId}
Get all audit logs for a specific user.

### GET /api/audit/export/{userId}
Export user data for GDPR compliance.

**Response:**
```json
{
  "report_id": "uuid",
  "status": "processing",
  "download_url": null,
  "expires_at": "2024-01-08T00:00:00Z"
}
```

### POST /api/audit/search
Advanced search in audit logs.

**Request Body:**
```json
{
  "query": "failed login attempts",
  "filters": {
    "severity": ["warning", "error"],
    "date_range": "last_7_days"
  }
}
```

### DELETE /api/audit/user/{userId}
Delete all user data (GDPR right to deletion).

### GET /api/compliance/report
Generate compliance report.

**Query Parameters:**
- `type`: Report type (gdpr, ccpa, sox, pci)
- `format`: Output format (pdf, json, csv)

---

## 2. Multi-Factor Authentication APIs

### POST /api/mfa/enroll
Enroll a new MFA device.

**Request Body:**
```json
{
  "device_name": "My Phone",
  "type": "totp"
}
```

**Response:**
```json
{
  "device_id": "uuid",
  "secret": "JBSWY3DPEHPK3PXP",
  "qr_code": "data:image/png;base64,...",
  "backup_codes": ["12345678", "87654321"],
  "verification_required": true
}
```

### POST /api/mfa/verify
Verify MFA code during authentication.

**Request Body:**
```json
{
  "device_id": "uuid",
  "code": "123456"
}
```

### GET /api/mfa/status
Get MFA enrollment status for current user.

### POST /api/mfa/totp/setup
Set up TOTP authentication.

**Response:**
```json
{
  "secret": "JBSWY3DPEHPK3PXP",
  "qr_code": "data:image/png;base64,...",
  "manual_entry_key": "JBSW Y3DP EHPK 3PXP"
}
```

### POST /api/mfa/totp/verify
Verify TOTP code.

### POST /api/mfa/webauthn/register
Register WebAuthn device.

**Response:**
```json
{
  "challenge": "base64...",
  "rp": {
    "id": "goat.example.com",
    "name": "GOAT Auth"
  },
  "user": {
    "id": "base64...",
    "name": "user@example.com",
    "displayName": "John Doe"
  },
  "pubKeyCredParams": [
    {"type": "public-key", "alg": -7}
  ]
}
```

### POST /api/mfa/webauthn/authenticate
Authenticate with WebAuthn.

### POST /api/mfa/backup-codes/generate
Generate new backup codes.

### POST /api/mfa/backup-codes/verify
Verify a backup code.

### DELETE /api/mfa/disable
Disable MFA for current user.

---

## 3. Federation & SSO APIs

### GET /api/sso/providers
List available SSO providers.

**Response:**
```json
{
  "providers": [
    {
      "id": "google",
      "name": "Google",
      "type": "oauth2",
      "enabled": true,
      "icon_url": "https://..."
    }
  ]
}
```

### POST /api/sso/saml/metadata
Get or generate SAML metadata.

### POST /api/sso/saml/acs
SAML Assertion Consumer Service endpoint.

### GET /api/sso/saml/slo
SAML Single Logout endpoint.

### POST /api/sso/oauth/{provider}/authorize
Initiate OAuth2 authorization flow.

**Response:**
```json
{
  "authorization_url": "https://provider.com/oauth/authorize?...",
  "state": "random_state"
}
```

### GET /api/sso/oauth/{provider}/callback
OAuth2 callback endpoint.

### POST /api/sso/ldap/test
Test LDAP connection.

**Request Body:**
```json
{
  "url": "ldap://example.com:389",
  "bind_dn": "cn=admin,dc=example,dc=com",
  "bind_password": "password",
  "base_dn": "dc=example,dc=com"
}
```

### POST /api/sso/federation/trust
Establish federation trust relationship.

---

## 4. Rate Limiting & Protection APIs

### GET /api/ratelimit/status
Get current rate limit status.

**Response:**
```json
{
  "limits": [
    {
      "type": "api",
      "limit": 1000,
      "remaining": 750,
      "reset_at": "2024-01-01T01:00:00Z"
    }
  ]
}
```

### GET /api/ratelimit/config
Get rate limit configuration.

### PUT /api/ratelimit/config
Update rate limit configuration (admin only).

**Request Body:**
```json
{
  "global": "10000/hour",
  "per_ip": "100/minute",
  "per_user": "1000/hour"
}
```

### GET /api/ratelimit/blocked
Get list of blocked IPs.

### DELETE /api/ratelimit/blocked/{ip}
Unblock an IP address.

### POST /api/ratelimit/whitelist
Add IP to whitelist.

**Request Body:**
```json
{
  "ip": "192.168.1.0/24",
  "description": "Office network"
}
```

### GET /api/protection/captcha
Get CAPTCHA challenge.

**Response:**
```json
{
  "challenge_id": "uuid",
  "image": "data:image/png;base64,...",
  "audio": "data:audio/mp3;base64,..."
}
```

### POST /api/protection/verify
Verify CAPTCHA or challenge response.

---

## 5. Webhook & Event APIs

### GET /api/webhooks
List configured webhooks.

### POST /api/webhooks
Create a new webhook.

**Request Body:**
```json
{
  "name": "My Webhook",
  "url": "https://example.com/webhook",
  "events": ["user.login", "user.logout"],
  "headers": {
    "X-Custom-Header": "value"
  },
  "secret": "webhook_secret"
}
```

### PUT /api/webhooks/{id}
Update webhook configuration.

### DELETE /api/webhooks/{id}
Delete a webhook.

### POST /api/webhooks/{id}/test
Test webhook with sample data.

### GET /api/events
Get event history.

**Query Parameters:**
- `types`: Comma-separated event types
- `start_time`: Start of time range
- `end_time`: End of time range
- `limit`: Max results

### GET /api/events/{id}
Get specific event details.

### POST /api/events/subscribe
Subscribe to event stream.

**Request Body:**
```json
{
  "events": ["user.*", "security.*"],
  "delivery": "webhook",
  "destination": "https://example.com/events"
}
```

### DELETE /api/events/subscribe/{id}
Unsubscribe from events.

### GET /api/events/stream
Server-Sent Events (SSE) endpoint for real-time events.

**Query Parameters:**
- `events`: Comma-separated event types to filter

---

## Rate Limiting Headers

All API responses include rate limiting headers:

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
X-RateLimit-Reset-After: 3600
```

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Invalid request parameters",
    "details": { ... }
  }
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}
```

### 403 Forbidden
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Insufficient permissions"
  }
}
```

### 429 Too Many Requests
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMITED",
    "message": "Rate limit exceeded",
    "retry_after": 3600
  }
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An internal error occurred",
    "request_id": "uuid"
  }
}
```

## WebSocket Events

Connect to `wss://api.goat.example.com/v2/ws` for real-time events.

### Authentication
Send authentication message after connection:
```json
{
  "type": "auth",
  "token": "jwt_token"
}
```

### Subscribe to Events
```json
{
  "type": "subscribe",
  "events": ["user.login", "security.alert"]
}
```

### Event Message Format
```json
{
  "type": "event",
  "event": {
    "id": "uuid",
    "type": "user.login",
    "timestamp": "2024-01-01T00:00:00Z",
    "data": { ... }
  }
}
```

## Webhook Payload Format

Webhooks receive POST requests with this payload:

```json
{
  "id": "uuid",
  "type": "user.login",
  "timestamp": "2024-01-01T00:00:00Z",
  "data": {
    "user_id": "uuid",
    "ip": "192.168.1.1",
    "user_agent": "..."
  },
  "metadata": {
    "version": "2.0",
    "source": "goat"
  }
}
```

### Webhook Signature Verification

Webhooks include an HMAC-SHA256 signature in the `X-Webhook-Signature` header:

```
X-Webhook-Signature: sha256=<hex_signature>
```

Verify using:
```go
expectedSig := hmac.New(sha256.New, []byte(webhook.Secret))
expectedSig.Write(requestBody)
signature := "sha256=" + hex.EncodeToString(expectedSig.Sum(nil))
```

## SDK Examples

### JavaScript/TypeScript
```javascript
import { GoatClient } from '@goat/sdk';

const client = new GoatClient({
  baseUrl: 'https://api.goat.example.com/v2',
  apiKey: 'your_api_key'
});

// Audit logs
const logs = await client.audit.getLogs({
  startTime: new Date('2024-01-01'),
  severity: ['warning', 'error']
});

// MFA enrollment
const mfa = await client.mfa.enroll({
  deviceName: 'My Phone',
  type: 'totp'
});

// Webhook management
const webhook = await client.webhooks.create({
  name: 'My Webhook',
  url: 'https://example.com/webhook',
  events: ['user.login']
});
```

### Python
```python
from goat import GoatClient

client = GoatClient(
    base_url='https://api.goat.example.com/v2',
    api_key='your_api_key'
)

# Audit logs
logs = client.audit.get_logs(
    start_time='2024-01-01',
    severity=['warning', 'error']
)

# MFA enrollment
mfa = client.mfa.enroll(
    device_name='My Phone',
    type='totp'
)

# Event streaming
for event in client.events.stream(['user.login', 'security.alert']):
    print(f"Event: {event.type} at {event.timestamp}")
```

### Go
```go
import "github.com/goat/sdk-go"

client := goat.NewClient(
    goat.WithBaseURL("https://api.goat.example.com/v2"),
    goat.WithAPIKey("your_api_key"),
)

// Audit logs
logs, err := client.Audit.GetLogs(ctx, &goat.AuditFilter{
    StartTime: time.Now().Add(-24 * time.Hour),
    Severity:  []string{"warning", "error"},
})

// MFA enrollment
mfa, err := client.MFA.Enroll(ctx, &goat.EnrollRequest{
    DeviceName: "My Phone",
    Type:       "totp",
})

// Webhook management
webhook, err := client.Webhooks.Create(ctx, &goat.Webhook{
    Name:   "My Webhook",
    URL:    "https://example.com/webhook",
    Events: []string{"user.login"},
})
```