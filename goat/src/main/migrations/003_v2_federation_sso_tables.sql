-- Migration: Create Federation and SSO tables for GOAT v2.0
-- Version: 003
-- Description: Adds SSO providers, SAML, OAuth2/OIDC, and LDAP integration

-- SSO providers table
CREATE TABLE IF NOT EXISTS sso_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(255) NOT NULL,
    provider_type VARCHAR(50) NOT NULL CHECK (provider_type IN ('saml', 'oauth2', 'oidc', 'ldap', 'active_directory')),
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    config JSONB NOT NULL, -- Provider-specific configuration
    metadata TEXT, -- SAML metadata XML
    certificate TEXT, -- X.509 certificate for SAML
    signing_certificate TEXT, -- For request signing
    encryption_certificate TEXT, -- For assertion encryption
    priority INTEGER NOT NULL DEFAULT 0,
    auto_provision_users BOOLEAN DEFAULT FALSE,
    sync_groups BOOLEAN DEFAULT FALSE,
    icon_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for SSO providers
CREATE INDEX idx_sso_providers_type ON sso_providers(provider_type);
CREATE INDEX idx_sso_providers_enabled ON sso_providers(enabled);

-- SAML configurations
CREATE TABLE IF NOT EXISTS saml_configurations (
    provider_id UUID PRIMARY KEY REFERENCES sso_providers(id) ON DELETE CASCADE,
    entity_id VARCHAR(500) NOT NULL,
    metadata_url TEXT,
    sso_url TEXT NOT NULL,
    slo_url TEXT,
    acs_url TEXT NOT NULL,
    name_id_format VARCHAR(255) DEFAULT 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
    sign_requests BOOLEAN DEFAULT TRUE,
    encrypt_assertions BOOLEAN DEFAULT FALSE,
    force_authn BOOLEAN DEFAULT FALSE,
    attribute_mapping JSONB,
    relay_state TEXT,
    binding VARCHAR(100) DEFAULT 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- OAuth2/OIDC configurations
CREATE TABLE IF NOT EXISTS oauth2_configurations (
    provider_id UUID PRIMARY KEY REFERENCES sso_providers(id) ON DELETE CASCADE,
    client_id VARCHAR(500) NOT NULL,
    client_secret TEXT NOT NULL, -- Encrypted
    auth_url TEXT NOT NULL,
    token_url TEXT NOT NULL,
    userinfo_url TEXT,
    jwks_url TEXT,
    issuer TEXT,
    scopes TEXT[] DEFAULT ARRAY['openid', 'profile', 'email'],
    redirect_uri TEXT NOT NULL,
    response_type VARCHAR(50) DEFAULT 'code',
    grant_type VARCHAR(50) DEFAULT 'authorization_code',
    claim_mapping JSONB,
    pkce_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- LDAP/AD configurations
CREATE TABLE IF NOT EXISTS ldap_configurations (
    provider_id UUID PRIMARY KEY REFERENCES sso_providers(id) ON DELETE CASCADE,
    url TEXT NOT NULL, -- ldap://example.com:389 or ldaps://example.com:636
    base_dn TEXT NOT NULL,
    bind_dn TEXT NOT NULL,
    bind_password TEXT NOT NULL, -- Encrypted
    user_search_base TEXT,
    user_search_filter TEXT DEFAULT '(uid={{username}})',
    group_search_base TEXT,
    group_search_filter TEXT,
    user_attributes JSONB,
    group_attributes JSONB,
    start_tls BOOLEAN DEFAULT FALSE,
    insecure_skip_verify BOOLEAN DEFAULT FALSE,
    connection_timeout INTEGER DEFAULT 10, -- seconds
    search_timeout INTEGER DEFAULT 30, -- seconds
    max_connections INTEGER DEFAULT 10,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Federation trust relationships
CREATE TABLE IF NOT EXISTS federation_trusts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    provider_id UUID REFERENCES sso_providers(id) ON DELETE CASCADE,
    trusted_entity VARCHAR(500) NOT NULL,
    trust_type VARCHAR(50) NOT NULL CHECK (trust_type IN ('inbound', 'outbound', 'bidirectional')),
    config JSONB,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(provider_id, trusted_entity)
);

-- SSO sessions table
CREATE TABLE IF NOT EXISTS sso_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES sso_providers(id) ON DELETE CASCADE,
    session_index VARCHAR(500), -- SAML session index
    name_id VARCHAR(500), -- SAML NameID
    access_token TEXT, -- OAuth2 access token (encrypted)
    refresh_token TEXT, -- OAuth2 refresh token (encrypted)
    id_token TEXT, -- OIDC ID token
    expires_at TIMESTAMPTZ,
    attributes JSONB, -- User attributes from IdP
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for SSO sessions
CREATE INDEX idx_sso_sessions_user_id ON sso_sessions(user_id);
CREATE INDEX idx_sso_sessions_provider_id ON sso_sessions(provider_id);
CREATE INDEX idx_sso_sessions_session_index ON sso_sessions(session_index);

-- SSO login attempts (for debugging and security)
CREATE TABLE IF NOT EXISTS sso_login_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID REFERENCES sso_providers(id) ON DELETE CASCADE,
    email VARCHAR(255),
    success BOOLEAN NOT NULL,
    error_message TEXT,
    saml_request_id VARCHAR(500),
    oauth_state VARCHAR(500),
    ip_address INET,
    user_agent TEXT,
    attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for SSO login attempts
CREATE INDEX idx_sso_login_attempts_provider_id ON sso_login_attempts(provider_id);
CREATE INDEX idx_sso_login_attempts_email ON sso_login_attempts(email);
CREATE INDEX idx_sso_login_attempts_attempted_at ON sso_login_attempts(attempted_at DESC);

-- User provider mappings (for account linking)
CREATE TABLE IF NOT EXISTS user_provider_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES sso_providers(id) ON DELETE CASCADE,
    external_id VARCHAR(500) NOT NULL, -- User ID from external provider
    email VARCHAR(255),
    username VARCHAR(255),
    attributes JSONB,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(provider_id, external_id),
    UNIQUE(user_id, provider_id)
);

-- Indexes for user provider mappings
CREATE INDEX idx_user_provider_mappings_user_id ON user_provider_mappings(user_id);
CREATE INDEX idx_user_provider_mappings_provider_id ON user_provider_mappings(provider_id);
CREATE INDEX idx_user_provider_mappings_external_id ON user_provider_mappings(external_id);

-- Group mappings for SSO
CREATE TABLE IF NOT EXISTS sso_group_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES sso_providers(id) ON DELETE CASCADE,
    external_group VARCHAR(500) NOT NULL,
    internal_role VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(provider_id, external_group)
);

-- Attribute mappings
CREATE TABLE IF NOT EXISTS sso_attribute_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES sso_providers(id) ON DELETE CASCADE,
    source_attribute VARCHAR(255) NOT NULL,
    target_attribute VARCHAR(255) NOT NULL,
    transform_function VARCHAR(100), -- e.g., 'lowercase', 'uppercase', 'trim'
    default_value TEXT,
    required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(provider_id, source_attribute)
);

-- SAML assertions cache (for replay prevention)
CREATE TABLE IF NOT EXISTS saml_assertion_cache (
    assertion_id VARCHAR(500) PRIMARY KEY,
    provider_id UUID REFERENCES sso_providers(id) ON DELETE CASCADE,
    not_on_or_after TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for SAML assertion cleanup
CREATE INDEX idx_saml_assertion_cache_not_on_or_after ON saml_assertion_cache(not_on_or_after);

-- OAuth state cache (for CSRF prevention)
CREATE TABLE IF NOT EXISTS oauth_state_cache (
    state VARCHAR(500) PRIMARY KEY,
    provider_id UUID REFERENCES sso_providers(id) ON DELETE CASCADE,
    redirect_uri TEXT,
    pkce_verifier TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '10 minutes')
);

-- Index for OAuth state cleanup
CREATE INDEX idx_oauth_state_cache_expires_at ON oauth_state_cache(expires_at);

-- Insert sample SSO providers (disabled by default)
INSERT INTO sso_providers (name, display_name, provider_type, enabled, config) VALUES
    ('google-oauth', 'Google', 'oauth2', FALSE, 
     '{"provider": "google", "icon": "google", "color": "#4285f4"}'::jsonb),
    ('github-oauth', 'GitHub', 'oauth2', FALSE,
     '{"provider": "github", "icon": "github", "color": "#333"}'::jsonb),
    ('microsoft-oauth', 'Microsoft', 'oidc', FALSE,
     '{"provider": "microsoft", "icon": "microsoft", "color": "#0078d4"}'::jsonb),
    ('okta-saml', 'Okta', 'saml', FALSE,
     '{"provider": "okta", "icon": "okta", "color": "#007dc1"}'::jsonb)
ON CONFLICT (name) DO NOTHING;

-- Triggers for updated_at
CREATE TRIGGER update_sso_providers_updated_at BEFORE UPDATE ON sso_providers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_saml_configurations_updated_at BEFORE UPDATE ON saml_configurations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_oauth2_configurations_updated_at BEFORE UPDATE ON oauth2_configurations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ldap_configurations_updated_at BEFORE UPDATE ON ldap_configurations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_federation_trusts_updated_at BEFORE UPDATE ON federation_trusts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_provider_mappings_updated_at BEFORE UPDATE ON user_provider_mappings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to clean up expired SSO data
CREATE OR REPLACE FUNCTION cleanup_expired_sso_data()
RETURNS void AS $$
BEGIN
    DELETE FROM saml_assertion_cache WHERE not_on_or_after < NOW();
    DELETE FROM oauth_state_cache WHERE expires_at < NOW();
    DELETE FROM sso_sessions WHERE expires_at < NOW() - INTERVAL '1 day';
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup (requires pg_cron extension)
-- Uncomment if pg_cron is available
-- SELECT cron.schedule('cleanup-sso-data', '0 * * * *', $$SELECT cleanup_expired_sso_data()$$);