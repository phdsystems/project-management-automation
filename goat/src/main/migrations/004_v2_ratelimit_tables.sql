-- Migration: Create Rate Limiting and DDoS Protection tables for GOAT v2.0
-- Version: 004
-- Description: Adds rate limiting, DDoS protection, and traffic management

-- Rate limit configurations
CREATE TABLE IF NOT EXISTS rate_limit_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    limit_type VARCHAR(50) NOT NULL CHECK (limit_type IN ('global', 'ip', 'user', 'endpoint', 'api_key')),
    strategy VARCHAR(50) NOT NULL CHECK (strategy IN ('fixed_window', 'sliding_window', 'token_bucket', 'leaky_bucket', 'adaptive')),
    limit_value BIGINT NOT NULL CHECK (limit_value > 0),
    window_seconds INTEGER NOT NULL CHECK (window_seconds > 0),
    burst_size BIGINT,
    action VARCHAR(50) NOT NULL CHECK (action IN ('block', 'throttle', 'captcha', 'challenge', 'log')),
    priority INTEGER NOT NULL DEFAULT 0,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    conditions JSONB, -- Conditional rules for applying this limit
    exemptions TEXT[], -- List of exempted IPs, users, or keys
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for rate limit configs
CREATE INDEX idx_rate_limit_configs_type ON rate_limit_configs(limit_type);
CREATE INDEX idx_rate_limit_configs_enabled ON rate_limit_configs(enabled);
CREATE INDEX idx_rate_limit_configs_priority ON rate_limit_configs(priority DESC);

-- Rate limit counters (for tracking current usage)
CREATE TABLE IF NOT EXISTS rate_limit_counters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_id UUID REFERENCES rate_limit_configs(id) ON DELETE CASCADE,
    identifier VARCHAR(500) NOT NULL, -- IP, user ID, API key, etc.
    counter BIGINT NOT NULL DEFAULT 0,
    window_start TIMESTAMPTZ NOT NULL,
    window_end TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(config_id, identifier, window_start)
);

-- Indexes for rate limit counters
CREATE INDEX idx_rate_limit_counters_identifier ON rate_limit_counters(identifier);
CREATE INDEX idx_rate_limit_counters_window_end ON rate_limit_counters(window_end);

-- Blocked IPs table
CREATE TABLE IF NOT EXISTS blocked_ips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ip_address INET NOT NULL UNIQUE,
    reason VARCHAR(500) NOT NULL,
    blocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    blocked_until TIMESTAMPTZ,
    permanent BOOLEAN NOT NULL DEFAULT FALSE,
    auto_blocked BOOLEAN NOT NULL DEFAULT FALSE,
    blocked_by UUID REFERENCES users(id) ON DELETE SET NULL,
    unblocked_at TIMESTAMPTZ,
    unblocked_by UUID REFERENCES users(id) ON DELETE SET NULL,
    metadata JSONB
);

-- Indexes for blocked IPs
CREATE INDEX idx_blocked_ips_ip_address ON blocked_ips(ip_address);
CREATE INDEX idx_blocked_ips_blocked_until ON blocked_ips(blocked_until);

-- IP whitelist table
CREATE TABLE IF NOT EXISTS ip_whitelist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ip_address INET,
    cidr_range CIDR,
    description TEXT,
    added_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    CHECK ((ip_address IS NOT NULL AND cidr_range IS NULL) OR 
           (ip_address IS NULL AND cidr_range IS NOT NULL))
);

-- Indexes for IP whitelist
CREATE INDEX idx_ip_whitelist_ip_address ON ip_whitelist(ip_address);
CREATE INDEX idx_ip_whitelist_cidr_range ON ip_whitelist(cidr_range);

-- DDoS protection status
CREATE TABLE IF NOT EXISTS ddos_protection_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    protection_level VARCHAR(50) CHECK (protection_level IN ('low', 'medium', 'high', 'critical')),
    activated_at TIMESTAMPTZ,
    activated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    deactivated_at TIMESTAMPTZ,
    deactivated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reason TEXT,
    auto_activated BOOLEAN DEFAULT FALSE,
    settings JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Attack detection logs
CREATE TABLE IF NOT EXISTS attack_detection_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attack_type VARCHAR(100) NOT NULL,
    severity VARCHAR(50) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    source_ips TEXT[],
    target_endpoints TEXT[],
    request_rate NUMERIC(10,2),
    peak_rate NUMERIC(10,2),
    total_requests BIGINT,
    blocked_requests BIGINT,
    action_taken VARCHAR(100),
    auto_mitigated BOOLEAN DEFAULT FALSE,
    details JSONB
);

-- Indexes for attack detection
CREATE INDEX idx_attack_detection_logs_detected_at ON attack_detection_logs(detected_at DESC);
CREATE INDEX idx_attack_detection_logs_severity ON attack_detection_logs(severity);

-- Challenge responses (for CAPTCHA, proof-of-work, etc.)
CREATE TABLE IF NOT EXISTS challenge_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_type VARCHAR(50) NOT NULL CHECK (challenge_type IN ('captcha', 'proof_of_work', 'javascript', 'custom')),
    challenge_data TEXT NOT NULL,
    ip_address INET NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    solved BOOLEAN NOT NULL DEFAULT FALSE,
    solved_at TIMESTAMPTZ,
    attempts INTEGER NOT NULL DEFAULT 0,
    max_attempts INTEGER NOT NULL DEFAULT 3
);

-- Indexes for challenge responses
CREATE INDEX idx_challenge_responses_ip_address ON challenge_responses(ip_address);
CREATE INDEX idx_challenge_responses_expires_at ON challenge_responses(expires_at);

-- Rate limit violations log
CREATE TABLE IF NOT EXISTS rate_limit_violations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_id UUID REFERENCES rate_limit_configs(id) ON DELETE SET NULL,
    identifier VARCHAR(500) NOT NULL,
    limit_type VARCHAR(50) NOT NULL,
    limit_value BIGINT NOT NULL,
    actual_value BIGINT NOT NULL,
    action_taken VARCHAR(50) NOT NULL,
    ip_address INET,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    endpoint VARCHAR(500),
    user_agent TEXT,
    violated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for violations
CREATE INDEX idx_rate_limit_violations_identifier ON rate_limit_violations(identifier);
CREATE INDEX idx_rate_limit_violations_violated_at ON rate_limit_violations(violated_at DESC);

-- Adaptive rate limiting metrics
CREATE TABLE IF NOT EXISTS adaptive_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_id UUID REFERENCES rate_limit_configs(id) ON DELETE CASCADE,
    metric_time TIMESTAMPTZ NOT NULL,
    total_requests BIGINT NOT NULL DEFAULT 0,
    allowed_requests BIGINT NOT NULL DEFAULT 0,
    blocked_requests BIGINT NOT NULL DEFAULT 0,
    error_count BIGINT NOT NULL DEFAULT 0,
    avg_response_time_ms NUMERIC(10,2),
    p95_response_time_ms NUMERIC(10,2),
    p99_response_time_ms NUMERIC(10,2),
    current_limit BIGINT,
    adjusted_limit BIGINT,
    cpu_usage NUMERIC(5,2),
    memory_usage NUMERIC(5,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for adaptive metrics
CREATE INDEX idx_adaptive_metrics_config_id ON adaptive_metrics(config_id);
CREATE INDEX idx_adaptive_metrics_metric_time ON adaptive_metrics(metric_time DESC);

-- Traffic patterns (for anomaly detection)
CREATE TABLE IF NOT EXISTS traffic_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_name VARCHAR(255) NOT NULL,
    pattern_type VARCHAR(50) NOT NULL CHECK (pattern_type IN ('normal', 'suspicious', 'attack')),
    time_window INTERVAL NOT NULL,
    request_rate_threshold NUMERIC(10,2),
    unique_ips_threshold INTEGER,
    error_rate_threshold NUMERIC(5,2),
    patterns JSONB, -- Detailed pattern signatures
    detected_count INTEGER NOT NULL DEFAULT 0,
    last_detected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default rate limit configurations
INSERT INTO rate_limit_configs (name, limit_type, strategy, limit_value, window_seconds, action) VALUES
    ('global_default', 'global', 'sliding_window', 10000, 60, 'throttle'),
    ('per_ip_default', 'ip', 'sliding_window', 100, 60, 'throttle'),
    ('per_user_default', 'user', 'token_bucket', 1000, 60, 'throttle'),
    ('login_endpoint', 'endpoint', 'fixed_window', 5, 300, 'block'),
    ('api_key_default', 'api_key', 'sliding_window', 5000, 3600, 'throttle')
ON CONFLICT (name) DO NOTHING;

-- Insert default traffic patterns
INSERT INTO traffic_patterns (pattern_name, pattern_type, time_window, request_rate_threshold, unique_ips_threshold, error_rate_threshold) VALUES
    ('normal_traffic', 'normal', INTERVAL '1 minute', 100, 50, 0.05),
    ('suspicious_spike', 'suspicious', INTERVAL '1 minute', 1000, 100, 0.10),
    ('ddos_attack', 'attack', INTERVAL '1 minute', 10000, 500, 0.50),
    ('brute_force', 'attack', INTERVAL '5 minutes', 50, 1, 0.90)
ON CONFLICT DO NOTHING;

-- Triggers for updated_at
CREATE TRIGGER update_rate_limit_configs_updated_at BEFORE UPDATE ON rate_limit_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rate_limit_counters_updated_at BEFORE UPDATE ON rate_limit_counters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_traffic_patterns_updated_at BEFORE UPDATE ON traffic_patterns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to clean up old rate limit data
CREATE OR REPLACE FUNCTION cleanup_old_rate_limit_data()
RETURNS void AS $$
BEGIN
    -- Delete old counters (older than 1 day)
    DELETE FROM rate_limit_counters WHERE window_end < NOW() - INTERVAL '1 day';
    
    -- Delete expired challenges
    DELETE FROM challenge_responses WHERE expires_at < NOW();
    
    -- Delete old violations (older than 30 days)
    DELETE FROM rate_limit_violations WHERE violated_at < NOW() - INTERVAL '30 days';
    
    -- Delete old adaptive metrics (older than 7 days)
    DELETE FROM adaptive_metrics WHERE metric_time < NOW() - INTERVAL '7 days';
    
    -- Unblock temporary blocks that have expired
    UPDATE blocked_ips 
    SET unblocked_at = NOW() 
    WHERE permanent = FALSE 
      AND blocked_until < NOW() 
      AND unblocked_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup (requires pg_cron extension)
-- Uncomment if pg_cron is available
-- SELECT cron.schedule('cleanup-rate-limit-data', '0 * * * *', $$SELECT cleanup_old_rate_limit_data()$$);

-- Function to check if IP is whitelisted
CREATE OR REPLACE FUNCTION is_ip_whitelisted(check_ip INET)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM ip_whitelist 
        WHERE (ip_address = check_ip OR check_ip <<= cidr_range)
          AND (expires_at IS NULL OR expires_at > NOW())
    );
END;
$$ LANGUAGE plpgsql;

-- Function to check if IP is blocked
CREATE OR REPLACE FUNCTION is_ip_blocked(check_ip INET)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM blocked_ips 
        WHERE ip_address = check_ip
          AND unblocked_at IS NULL
          AND (permanent = TRUE OR blocked_until > NOW())
    );
END;
$$ LANGUAGE plpgsql;