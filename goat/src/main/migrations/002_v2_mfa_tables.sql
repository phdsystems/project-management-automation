-- Migration: Create MFA tables for GOAT v2.0
-- Version: 002
-- Description: Adds multi-factor authentication support

-- MFA devices table
CREATE TABLE IF NOT EXISTS mfa_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    device_type VARCHAR(50) NOT NULL CHECK (device_type IN ('totp', 'hotp', 'sms', 'email', 'webauthn', 'backup')),
    secret TEXT, -- Encrypted
    counter BIGINT DEFAULT 0, -- For HOTP
    phone_number VARCHAR(50), -- For SMS
    email VARCHAR(255), -- For Email OTP
    public_key BYTEA, -- For WebAuthn
    credential_id BYTEA, -- For WebAuthn
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- Indexes for mfa_devices
CREATE INDEX idx_mfa_devices_user_id ON mfa_devices(user_id);
CREATE INDEX idx_mfa_devices_type ON mfa_devices(device_type);
CREATE INDEX idx_mfa_devices_verified ON mfa_devices(verified);

-- Backup codes table
CREATE TABLE IF NOT EXISTS mfa_backup_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash VARCHAR(255) NOT NULL, -- Hashed backup code
    used BOOLEAN NOT NULL DEFAULT FALSE,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '1 year')
);

-- Indexes for backup codes
CREATE INDEX idx_mfa_backup_codes_user_id ON mfa_backup_codes(user_id);
CREATE INDEX idx_mfa_backup_codes_used ON mfa_backup_codes(used);

-- MFA policies table
CREATE TABLE IF NOT EXISTS mfa_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    required BOOLEAN NOT NULL DEFAULT FALSE,
    allowed_factors TEXT[] NOT NULL DEFAULT ARRAY['totp', 'sms', 'email', 'webauthn', 'backup'],
    minimum_factors INTEGER NOT NULL DEFAULT 1 CHECK (minimum_factors >= 1),
    grace_period_hours INTEGER DEFAULT 0,
    remember_device_enabled BOOLEAN DEFAULT TRUE,
    device_ttl_hours INTEGER DEFAULT 720, -- 30 days
    priority INTEGER NOT NULL DEFAULT 0,
    conditions JSONB, -- Conditional application rules
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User MFA settings table
CREATE TABLE IF NOT EXISTS user_mfa_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    mfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    preferred_method VARCHAR(50),
    policy_id UUID REFERENCES mfa_policies(id) ON DELETE SET NULL,
    enforcement_date TIMESTAMPTZ, -- When MFA becomes mandatory for this user
    bypass_codes TEXT[], -- Temporary bypass codes for support
    bypass_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trusted devices table
CREATE TABLE IF NOT EXISTS mfa_trusted_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_fingerprint VARCHAR(255) NOT NULL,
    device_name VARCHAR(255),
    browser VARCHAR(100),
    operating_system VARCHAR(100),
    ip_address INET,
    trusted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    revoked_at TIMESTAMPTZ,
    UNIQUE(user_id, device_fingerprint)
);

-- Indexes for trusted devices
CREATE INDEX idx_mfa_trusted_devices_user_id ON mfa_trusted_devices(user_id);
CREATE INDEX idx_mfa_trusted_devices_fingerprint ON mfa_trusted_devices(device_fingerprint);
CREATE INDEX idx_mfa_trusted_devices_expires_at ON mfa_trusted_devices(expires_at);

-- MFA verification attempts table (for rate limiting and security)
CREATE TABLE IF NOT EXISTS mfa_verification_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES mfa_devices(id) ON DELETE CASCADE,
    ip_address INET,
    success BOOLEAN NOT NULL,
    failure_reason VARCHAR(255),
    attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for verification attempts
CREATE INDEX idx_mfa_verification_attempts_user_id ON mfa_verification_attempts(user_id);
CREATE INDEX idx_mfa_verification_attempts_attempted_at ON mfa_verification_attempts(attempted_at DESC);

-- WebAuthn credentials table
CREATE TABLE IF NOT EXISTS webauthn_credentials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    credential_id BYTEA NOT NULL UNIQUE,
    public_key BYTEA NOT NULL,
    sign_count INTEGER NOT NULL DEFAULT 0,
    aaguid BYTEA, -- Authenticator Attestation GUID
    attestation_type VARCHAR(50),
    transports TEXT[],
    authenticator_attachment VARCHAR(50),
    user_verified BOOLEAN DEFAULT FALSE,
    backup_eligible BOOLEAN DEFAULT FALSE,
    backup_state BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_used_at TIMESTAMPTZ
);

-- Indexes for WebAuthn credentials
CREATE INDEX idx_webauthn_credentials_user_id ON webauthn_credentials(user_id);
CREATE INDEX idx_webauthn_credentials_credential_id ON webauthn_credentials(credential_id);

-- OTP storage for SMS/Email (temporary storage)
CREATE TABLE IF NOT EXISTS otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash VARCHAR(255) NOT NULL,
    delivery_method VARCHAR(20) NOT NULL CHECK (delivery_method IN ('sms', 'email')),
    destination VARCHAR(255) NOT NULL, -- Phone number or email
    attempts INTEGER NOT NULL DEFAULT 0,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '10 minutes'),
    verified_at TIMESTAMPTZ
);

-- Indexes for OTP codes
CREATE INDEX idx_otp_codes_user_id ON otp_codes(user_id);
CREATE INDEX idx_otp_codes_expires_at ON otp_codes(expires_at);

-- Insert default MFA policies
INSERT INTO mfa_policies (name, description, required, allowed_factors, minimum_factors) VALUES
    ('default', 'Default MFA policy', FALSE, ARRAY['totp', 'sms', 'email', 'webauthn', 'backup'], 1),
    ('high_security', 'High security MFA policy', TRUE, ARRAY['totp', 'webauthn'], 2),
    ('admin', 'Administrator MFA policy', TRUE, ARRAY['totp', 'webauthn', 'backup'], 1)
ON CONFLICT (name) DO NOTHING;

-- Triggers for updated_at
CREATE TRIGGER update_mfa_devices_updated_at BEFORE UPDATE ON mfa_devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mfa_policies_updated_at BEFORE UPDATE ON mfa_policies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_mfa_settings_updated_at BEFORE UPDATE ON user_mfa_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to clean up expired OTP codes
CREATE OR REPLACE FUNCTION cleanup_expired_otp_codes()
RETURNS void AS $$
BEGIN
    DELETE FROM otp_codes WHERE expires_at < NOW();
    DELETE FROM mfa_backup_codes WHERE expires_at < NOW() AND used = FALSE;
    DELETE FROM mfa_trusted_devices WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup (requires pg_cron extension)
-- Uncomment if pg_cron is available
-- SELECT cron.schedule('cleanup-otp-codes', '*/10 * * * *', $$SELECT cleanup_expired_otp_codes()$$);