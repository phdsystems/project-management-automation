package mfa

import (
	"context"
	"crypto/rand"
	"encoding/base32"
	"encoding/base64"
	"fmt"
	"net/url"
	"time"
)

// FactorType represents the type of MFA factor
type FactorType string

const (
	FactorTypeTOTP     FactorType = "totp"
	FactorTypeHOTP     FactorType = "hotp"
	FactorTypeSMS      FactorType = "sms"
	FactorTypeEmail    FactorType = "email"
	FactorTypeWebAuthn FactorType = "webauthn"
	FactorTypeBackup   FactorType = "backup"
)

// Device represents an MFA device
type Device struct {
	ID           string     `json:"id" db:"id"`
	UserID       string     `json:"user_id" db:"user_id"`
	Name         string     `json:"name" db:"name"`
	Type         FactorType `json:"type" db:"type"`
	Secret       string     `json:"-" db:"secret"`  // Encrypted
	Counter      int64      `json:"-" db:"counter"` // For HOTP
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
	LastUsedAt   *time.Time `json:"last_used_at,omitempty" db:"last_used_at"`
	Verified     bool       `json:"verified" db:"verified"`
	BackupCodes  []string   `json:"-" db:"backup_codes"`  // Encrypted
	PublicKey    []byte     `json:"-" db:"public_key"`    // For WebAuthn
	CredentialID []byte     `json:"-" db:"credential_id"` // For WebAuthn
}

// EnrollmentRequest represents a request to enroll a new MFA device
type EnrollmentRequest struct {
	UserID     string                 `json:"user_id"`
	DeviceName string                 `json:"device_name"`
	Type       FactorType             `json:"type"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
}

// EnrollmentResponse represents the response to an enrollment request
type EnrollmentResponse struct {
	DeviceID             string   `json:"device_id"`
	Secret               string   `json:"secret,omitempty"`  // For TOTP/HOTP
	QRCode               string   `json:"qr_code,omitempty"` // Base64 encoded QR image
	BackupCodes          []string `json:"backup_codes,omitempty"`
	Challenge            []byte   `json:"challenge,omitempty"` // For WebAuthn
	RP                   *RPInfo  `json:"rp,omitempty"`        // For WebAuthn
	VerificationRequired bool     `json:"verification_required"`
}

// RPInfo represents Relying Party information for WebAuthn
type RPInfo struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

// VerificationRequest represents a request to verify an MFA code
type VerificationRequest struct {
	UserID       string `json:"user_id"`
	DeviceID     string `json:"device_id,omitempty"`
	Code         string `json:"code,omitempty"`
	ResponseData []byte `json:"response_data,omitempty"` // For WebAuthn
}

// VerificationResponse represents the response to a verification request
type VerificationResponse struct {
	Valid       bool   `json:"valid"`
	DeviceID    string `json:"device_id,omitempty"`
	DeviceName  string `json:"device_name,omitempty"`
	NextCounter int64  `json:"-"` // For HOTP
}

// MFAService defines the interface for MFA operations
type MFAService interface {
	// EnrollDevice enrolls a new MFA device for a user
	EnrollDevice(ctx context.Context, req *EnrollmentRequest) (*EnrollmentResponse, error)

	// VerifyDevice verifies the initial setup of an MFA device
	VerifyDevice(ctx context.Context, userID, deviceID, code string) error

	// VerifyCode verifies an MFA code during authentication
	VerifyCode(ctx context.Context, req *VerificationRequest) (*VerificationResponse, error)

	// ListDevices lists all MFA devices for a user
	ListDevices(ctx context.Context, userID string) ([]*Device, error)

	// GetDevice retrieves a specific MFA device
	GetDevice(ctx context.Context, userID, deviceID string) (*Device, error)

	// RemoveDevice removes an MFA device
	RemoveDevice(ctx context.Context, userID, deviceID string) error

	// GenerateBackupCodes generates new backup codes for a user
	GenerateBackupCodes(ctx context.Context, userID string, count int) ([]string, error)

	// VerifyBackupCode verifies and consumes a backup code
	VerifyBackupCode(ctx context.Context, userID, code string) (bool, error)

	// IsEnrolled checks if a user has any MFA devices enrolled
	IsEnrolled(ctx context.Context, userID string) (bool, error)

	// RequiresMFA checks if MFA is required for a user
	RequiresMFA(ctx context.Context, userID string) (bool, error)
}

// TOTPProvider handles TOTP operations
type TOTPProvider interface {
	// GenerateSecret generates a new TOTP secret
	GenerateSecret() (string, error)

	// GenerateQRCode generates a QR code for TOTP setup
	GenerateQRCode(secret, issuer, accountName string) ([]byte, error)

	// ValidateCode validates a TOTP code
	ValidateCode(secret, code string) bool

	// GetURI generates the otpauth:// URI for TOTP
	GetURI(secret, issuer, accountName string) string
}

// HOTPProvider handles HOTP operations
type HOTPProvider interface {
	// GenerateSecret generates a new HOTP secret
	GenerateSecret() (string, error)

	// ValidateCode validates an HOTP code and returns the next counter
	ValidateCode(secret string, code string, counter int64) (bool, int64)

	// GenerateCode generates an HOTP code for a given counter
	GenerateCode(secret string, counter int64) string
}

// SMSProvider handles SMS OTP operations
type SMSProvider interface {
	// SendOTP sends an OTP via SMS
	SendOTP(ctx context.Context, phoneNumber, code string) error

	// GenerateOTP generates a random OTP
	GenerateOTP() string

	// ValidatePhoneNumber validates a phone number format
	ValidatePhoneNumber(phoneNumber string) error
}

// EmailProvider handles Email OTP operations
type EmailProvider interface {
	// SendOTP sends an OTP via email
	SendOTP(ctx context.Context, email, code string) error

	// GenerateOTP generates a random OTP
	GenerateOTP() string

	// ValidateEmail validates an email format
	ValidateEmail(email string) error
}

// WebAuthnProvider handles WebAuthn operations
type WebAuthnProvider interface {
	// BeginRegistration starts WebAuthn registration
	BeginRegistration(ctx context.Context, userID string) (*RegistrationOptions, error)

	// FinishRegistration completes WebAuthn registration
	FinishRegistration(ctx context.Context, userID string, response []byte) (*Device, error)

	// BeginAuthentication starts WebAuthn authentication
	BeginAuthentication(ctx context.Context, userID string) (*AuthenticationOptions, error)

	// FinishAuthentication completes WebAuthn authentication
	FinishAuthentication(ctx context.Context, userID string, response []byte) (*VerificationResponse, error)
}

// RegistrationOptions for WebAuthn registration
type RegistrationOptions struct {
	Challenge        []byte            `json:"challenge"`
	RP               RPInfo            `json:"rp"`
	User             UserInfo          `json:"user"`
	PubKeyCredParams []PubKeyCredParam `json:"pubKeyCredParams"`
	Timeout          int               `json:"timeout"`
	Attestation      string            `json:"attestation"`
}

// AuthenticationOptions for WebAuthn authentication
type AuthenticationOptions struct {
	Challenge        []byte              `json:"challenge"`
	Timeout          int                 `json:"timeout"`
	RPId             string              `json:"rpId"`
	AllowCredentials []AllowedCredential `json:"allowCredentials"`
	UserVerification string              `json:"userVerification"`
}

// UserInfo for WebAuthn
type UserInfo struct {
	ID          []byte `json:"id"`
	Name        string `json:"name"`
	DisplayName string `json:"displayName"`
}

// PubKeyCredParam for WebAuthn
type PubKeyCredParam struct {
	Type string `json:"type"`
	Alg  int    `json:"alg"`
}

// AllowedCredential for WebAuthn
type AllowedCredential struct {
	Type       string   `json:"type"`
	ID         []byte   `json:"id"`
	Transports []string `json:"transports,omitempty"`
}

// BackupCodeGenerator generates backup codes
type BackupCodeGenerator struct {
	length int
}

// NewBackupCodeGenerator creates a new backup code generator
func NewBackupCodeGenerator(length int) *BackupCodeGenerator {
	if length < 8 {
		length = 8
	}
	return &BackupCodeGenerator{length: length}
}

// Generate generates a single backup code
func (g *BackupCodeGenerator) Generate() (string, error) {
	bytes := make([]byte, g.length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return base32.StdEncoding.EncodeToString(bytes)[:g.length], nil
}

// GenerateBatch generates multiple backup codes
func (g *BackupCodeGenerator) GenerateBatch(count int) ([]string, error) {
	codes := make([]string, count)
	for i := 0; i < count; i++ {
		code, err := g.Generate()
		if err != nil {
			return nil, err
		}
		codes[i] = code
	}
	return codes, nil
}

// OTPStore stores temporary OTP codes
type OTPStore interface {
	// Store stores an OTP with expiration
	Store(ctx context.Context, key, code string, expiration time.Duration) error

	// Verify verifies and removes an OTP
	Verify(ctx context.Context, key, code string) (bool, error)

	// Delete removes an OTP
	Delete(ctx context.Context, key string) error
}

// MFAPolicy defines MFA requirements for users
type MFAPolicy struct {
	Required       bool          `json:"required"`
	AllowedFactors []FactorType  `json:"allowed_factors"`
	MinimumFactors int           `json:"minimum_factors"`
	GracePeriod    time.Duration `json:"grace_period"`
	RememberDevice bool          `json:"remember_device"`
	DeviceTTL      time.Duration `json:"device_ttl"`
}

// MFAPolicyEngine evaluates MFA policies
type MFAPolicyEngine interface {
	// GetPolicy retrieves the MFA policy for a user
	GetPolicy(ctx context.Context, userID string) (*MFAPolicy, error)

	// EvaluatePolicy determines if MFA is required for an action
	EvaluatePolicy(ctx context.Context, userID, action string) (bool, error)

	// UpdatePolicy updates the MFA policy for a user or group
	UpdatePolicy(ctx context.Context, identifier string, policy *MFAPolicy) error
}

// GenerateSecret generates a random secret for TOTP/HOTP
func GenerateSecret() (string, error) {
	secret := make([]byte, 20)
	if _, err := rand.Read(secret); err != nil {
		return "", fmt.Errorf("failed to generate secret: %w", err)
	}
	return base32.StdEncoding.EncodeToString(secret), nil
}

// GenerateOTPAuthURI generates an otpauth:// URI
func GenerateOTPAuthURI(factorType FactorType, secret, issuer, accountName string, params map[string]string) string {
	label := fmt.Sprintf("%s:%s", issuer, accountName)
	values := url.Values{}
	values.Set("secret", secret)
	values.Set("issuer", issuer)
	for key, value := range params {
		values.Set(key, value)
	}

	return (&url.URL{
		Scheme:   "otpauth",
		Host:     string(factorType),
		Path:     "/" + url.PathEscape(label),
		RawQuery: values.Encode(),
	}).String()
}

// EncodeQRCode encodes data as a QR code image
func EncodeQRCode(data string) (string, error) {
	// This would use a QR code library to generate the image
	// Returning base64 encoded PNG image
	// Placeholder implementation
	return base64.StdEncoding.EncodeToString([]byte(data)), nil
}
