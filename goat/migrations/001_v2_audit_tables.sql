-- Migration: Create audit and compliance tables for GOAT v2.0
-- Version: 001
-- Description: Adds audit logging, compliance tracking, and security monitoring tables

-- Audit logs table
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    event_type VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('info', 'warning', 'error', 'critical')),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR(255),
    ip INET,
    user_agent TEXT,
    resource VARCHAR(255),
    action VARCHAR(100) NOT NULL,
    result VARCHAR(50) NOT NULL,
    details JSONB,
    error_msg TEXT,
    geo_location JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for audit_logs
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp DESC);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_event_type ON audit_logs(event_type);
CREATE INDEX idx_audit_logs_severity ON audit_logs(severity);
CREATE INDEX idx_audit_logs_ip ON audit_logs(ip);
CREATE INDEX idx_audit_logs_session_id ON audit_logs(session_id);

-- Compliance reports table
CREATE TABLE IF NOT EXISTS compliance_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('gdpr', 'ccpa', 'audit', 'security')),
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    data_export_url TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Security alerts table
CREATE TABLE IF NOT EXISTS security_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    alert_type VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('info', 'warning', 'error', 'critical')),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    actions TEXT[],
    resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Anomaly detection tracking
CREATE TABLE IF NOT EXISTS anomaly_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    anomaly_type VARCHAR(100) NOT NULL,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    confidence_score DECIMAL(5,2) CHECK (confidence_score >= 0 AND confidence_score <= 100),
    details JSONB,
    action_taken VARCHAR(100),
    false_positive BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Data retention policies
CREATE TABLE IF NOT EXISTS data_retention_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data_type VARCHAR(100) NOT NULL UNIQUE,
    retention_days INTEGER NOT NULL CHECK (retention_days > 0),
    delete_after_days INTEGER,
    archive_enabled BOOLEAN DEFAULT FALSE,
    archive_location TEXT,
    last_cleanup TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default retention policies
INSERT INTO data_retention_policies (data_type, retention_days, delete_after_days, archive_enabled) VALUES
    ('audit_logs', 90, 365, TRUE),
    ('security_alerts', 180, NULL, TRUE),
    ('compliance_reports', 2555, NULL, TRUE), -- 7 years
    ('user_sessions', 30, 90, FALSE),
    ('failed_logins', 30, 90, FALSE)
ON CONFLICT (data_type) DO NOTHING;

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_compliance_reports_updated_at BEFORE UPDATE ON compliance_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_security_alerts_updated_at BEFORE UPDATE ON security_alerts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_data_retention_policies_updated_at BEFORE UPDATE ON data_retention_policies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Partitioning for audit_logs (monthly partitions)
-- This improves performance for large-scale audit logging
CREATE TABLE IF NOT EXISTS audit_logs_template (LIKE audit_logs INCLUDING ALL);

-- Function to create monthly partitions
CREATE OR REPLACE FUNCTION create_monthly_audit_partition()
RETURNS void AS $$
DECLARE
    start_date date;
    end_date date;
    partition_name text;
BEGIN
    start_date := date_trunc('month', CURRENT_DATE);
    end_date := start_date + interval '1 month';
    partition_name := 'audit_logs_' || to_char(start_date, 'YYYY_MM');
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF audit_logs
        FOR VALUES FROM (%L) TO (%L)', partition_name, start_date, end_date);
END;
$$ LANGUAGE plpgsql;

-- Create current and next month partitions
SELECT create_monthly_audit_partition();

-- Schedule automatic partition creation (requires pg_cron extension)
-- Uncomment if pg_cron is available
-- SELECT cron.schedule('create-audit-partitions', '0 0 1 * *', $$SELECT create_monthly_audit_partition()$$);