-- Migration: Create Events and Webhooks tables for GOAT v2.0
-- Version: 005
-- Description: Adds event system, webhooks, and event streaming infrastructure

-- Events table
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(100) NOT NULL,
    priority VARCHAR(20) NOT NULL CHECK (priority IN ('low', 'normal', 'high', 'critical')),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    resource VARCHAR(500),
    action VARCHAR(100),
    result VARCHAR(50),
    data JSONB,
    metadata JSONB,
    correlation_id UUID, -- For tracing related events
    parent_event_id UUID REFERENCES events(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for events
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_timestamp ON events(timestamp DESC);
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_priority ON events(priority);
CREATE INDEX idx_events_correlation_id ON events(correlation_id);
CREATE INDEX idx_events_data_gin ON events USING gin(data);

-- Webhooks table
CREATE TABLE IF NOT EXISTS webhooks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    url TEXT NOT NULL,
    events TEXT[] NOT NULL, -- Array of event types to subscribe to
    headers JSONB, -- Custom headers to include
    secret VARCHAR(255), -- For HMAC signing (encrypted)
    active BOOLEAN NOT NULL DEFAULT TRUE,
    retry_max_attempts INTEGER DEFAULT 3,
    retry_initial_delay_ms INTEGER DEFAULT 1000,
    retry_max_delay_ms INTEGER DEFAULT 60000,
    retry_multiplier NUMERIC(3,2) DEFAULT 2.0,
    timeout_seconds INTEGER DEFAULT 30,
    filters JSONB, -- Additional filtering rules
    transform_template TEXT, -- Optional transformation template
    failure_count INTEGER NOT NULL DEFAULT 0,
    success_count INTEGER NOT NULL DEFAULT 0,
    last_triggered_at TIMESTAMPTZ,
    last_success_at TIMESTAMPTZ,
    last_failure_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for webhooks
CREATE INDEX idx_webhooks_active ON webhooks(active);
CREATE INDEX idx_webhooks_events_gin ON webhooks USING gin(events);

-- Webhook deliveries table
CREATE TABLE IF NOT EXISTS webhook_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    webhook_id UUID NOT NULL REFERENCES webhooks(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    method VARCHAR(10) NOT NULL DEFAULT 'POST',
    headers JSONB,
    payload JSONB NOT NULL,
    response_status INTEGER,
    response_headers JSONB,
    response_body TEXT,
    success BOOLEAN NOT NULL DEFAULT FALSE,
    error_message TEXT,
    attempts INTEGER NOT NULL DEFAULT 1,
    delivered_at TIMESTAMPTZ,
    next_retry_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for webhook deliveries
CREATE INDEX idx_webhook_deliveries_webhook_id ON webhook_deliveries(webhook_id);
CREATE INDEX idx_webhook_deliveries_event_id ON webhook_deliveries(event_id);
CREATE INDEX idx_webhook_deliveries_success ON webhook_deliveries(success);
CREATE INDEX idx_webhook_deliveries_next_retry_at ON webhook_deliveries(next_retry_at);
CREATE INDEX idx_webhook_deliveries_created_at ON webhook_deliveries(created_at DESC);

-- Event subscriptions (for various delivery mechanisms)
CREATE TABLE IF NOT EXISTS event_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    subscription_type VARCHAR(50) NOT NULL CHECK (subscription_type IN ('webhook', 'stream', 'queue', 'email', 'slack')),
    events TEXT[] NOT NULL,
    destination TEXT NOT NULL, -- URL, queue name, email address, etc.
    config JSONB, -- Type-specific configuration
    filters JSONB,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for subscriptions
CREATE INDEX idx_event_subscriptions_type ON event_subscriptions(subscription_type);
CREATE INDEX idx_event_subscriptions_active ON event_subscriptions(active);
CREATE INDEX idx_event_subscriptions_events_gin ON event_subscriptions USING gin(events);

-- Event streams (for SSE/WebSocket connections)
CREATE TABLE IF NOT EXISTS event_streams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stream_key VARCHAR(255) NOT NULL UNIQUE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    events TEXT[], -- Event types to stream, NULL means all
    filters JSONB,
    connection_type VARCHAR(20) CHECK (connection_type IN ('sse', 'websocket')),
    connected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    disconnected_at TIMESTAMPTZ,
    last_event_id UUID REFERENCES events(id) ON DELETE SET NULL,
    metadata JSONB
);

-- Indexes for event streams
CREATE INDEX idx_event_streams_user_id ON event_streams(user_id);
CREATE INDEX idx_event_streams_stream_key ON event_streams(stream_key);

-- Dead letter queue for failed deliveries
CREATE TABLE IF NOT EXISTS dead_letter_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_id UUID REFERENCES webhook_deliveries(id) ON DELETE CASCADE,
    webhook_id UUID REFERENCES webhooks(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    failure_reason TEXT NOT NULL,
    max_retries_exceeded BOOLEAN DEFAULT FALSE,
    reprocessed BOOLEAN DEFAULT FALSE,
    reprocessed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for dead letter queue
CREATE INDEX idx_dead_letter_queue_webhook_id ON dead_letter_queue(webhook_id);
CREATE INDEX idx_dead_letter_queue_reprocessed ON dead_letter_queue(reprocessed);

-- Event aggregations (for statistics and monitoring)
CREATE TABLE IF NOT EXISTS event_aggregations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregation_window INTERVAL NOT NULL,
    window_start TIMESTAMPTZ NOT NULL,
    window_end TIMESTAMPTZ NOT NULL,
    total_events BIGINT NOT NULL DEFAULT 0,
    events_by_type JSONB,
    events_by_user JSONB,
    events_by_priority JSONB,
    error_count BIGINT DEFAULT 0,
    avg_processing_time_ms NUMERIC(10,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for aggregations
CREATE INDEX idx_event_aggregations_window_start ON event_aggregations(window_start DESC);
CREATE INDEX idx_event_aggregations_window_end ON event_aggregations(window_end DESC);

-- Event routing rules
CREATE TABLE IF NOT EXISTS event_routing_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    priority INTEGER NOT NULL DEFAULT 0,
    event_types TEXT[],
    conditions JSONB, -- Complex routing conditions
    destinations JSONB, -- Array of destination configurations
    transformations JSONB, -- Data transformation rules
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for routing rules
CREATE INDEX idx_event_routing_rules_priority ON event_routing_rules(priority DESC);
CREATE INDEX idx_event_routing_rules_active ON event_routing_rules(active);

-- Event transformations
CREATE TABLE IF NOT EXISTS event_transformations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    transformation_type VARCHAR(50) NOT NULL CHECK (transformation_type IN ('filter', 'map', 'aggregate', 'enrich')),
    source_event_type VARCHAR(100),
    target_event_type VARCHAR(100),
    transformation_script TEXT, -- Transformation logic (could be JSONPath, JavaScript, etc.)
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Webhook test results
CREATE TABLE IF NOT EXISTS webhook_test_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    webhook_id UUID NOT NULL REFERENCES webhooks(id) ON DELETE CASCADE,
    test_event JSONB NOT NULL,
    request_headers JSONB,
    request_body TEXT,
    response_status INTEGER,
    response_headers JSONB,
    response_body TEXT,
    response_time_ms INTEGER,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    tested_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for test results
CREATE INDEX idx_webhook_test_results_webhook_id ON webhook_test_results(webhook_id);
CREATE INDEX idx_webhook_test_results_tested_at ON webhook_test_results(tested_at DESC);

-- Event type definitions (for schema validation)
CREATE TABLE IF NOT EXISTS event_type_definitions (
    event_type VARCHAR(100) PRIMARY KEY,
    description TEXT,
    schema JSONB, -- JSON Schema for validation
    required_fields TEXT[],
    sample_event JSONB,
    deprecated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default event type definitions
INSERT INTO event_type_definitions (event_type, description, required_fields) VALUES
    ('user.login', 'User login event', ARRAY['user_id', 'ip_address']),
    ('user.logout', 'User logout event', ARRAY['user_id']),
    ('user.created', 'New user created', ARRAY['user_id', 'email']),
    ('user.updated', 'User profile updated', ARRAY['user_id']),
    ('user.deleted', 'User account deleted', ARRAY['user_id']),
    ('mfa.enabled', 'MFA enabled for user', ARRAY['user_id', 'device_type']),
    ('mfa.verified', 'MFA verification successful', ARRAY['user_id', 'device_id']),
    ('security.alert', 'Security alert triggered', ARRAY['severity', 'description']),
    ('api.request', 'API request made', ARRAY['endpoint', 'method']),
    ('webhook.delivered', 'Webhook successfully delivered', ARRAY['webhook_id', 'event_id'])
ON CONFLICT (event_type) DO NOTHING;

-- Triggers for updated_at
CREATE TRIGGER update_webhooks_updated_at BEFORE UPDATE ON webhooks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_event_subscriptions_updated_at BEFORE UPDATE ON event_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_event_routing_rules_updated_at BEFORE UPDATE ON event_routing_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_event_transformations_updated_at BEFORE UPDATE ON event_transformations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_event_type_definitions_updated_at BEFORE UPDATE ON event_type_definitions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to queue webhook delivery
CREATE OR REPLACE FUNCTION queue_webhook_delivery(p_event_id UUID)
RETURNS void AS $$
DECLARE
    v_webhook RECORD;
    v_event RECORD;
BEGIN
    -- Get the event
    SELECT * INTO v_event FROM events WHERE id = p_event_id;
    
    -- Find matching webhooks
    FOR v_webhook IN 
        SELECT * FROM webhooks 
        WHERE active = TRUE 
          AND v_event.event_type = ANY(events)
    LOOP
        -- Check filters if any
        IF v_webhook.filters IS NULL OR 
           jsonb_contains(v_event.data, v_webhook.filters) THEN
            -- Insert delivery record
            INSERT INTO webhook_deliveries (
                webhook_id, event_id, url, payload
            ) VALUES (
                v_webhook.id, p_event_id, v_webhook.url, 
                jsonb_build_object(
                    'event_id', v_event.id,
                    'event_type', v_event.event_type,
                    'timestamp', v_event.timestamp,
                    'data', v_event.data
                )
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up old event data
CREATE OR REPLACE FUNCTION cleanup_old_event_data()
RETURNS void AS $$
BEGIN
    -- Delete old events (older than 90 days)
    DELETE FROM events WHERE timestamp < NOW() - INTERVAL '90 days';
    
    -- Delete old webhook deliveries (older than 30 days)
    DELETE FROM webhook_deliveries WHERE created_at < NOW() - INTERVAL '30 days';
    
    -- Delete old test results (older than 7 days)
    DELETE FROM webhook_test_results WHERE tested_at < NOW() - INTERVAL '7 days';
    
    -- Delete old aggregations (older than 30 days)
    DELETE FROM event_aggregations WHERE window_end < NOW() - INTERVAL '30 days';
    
    -- Clean up disconnected streams (older than 1 day)
    DELETE FROM event_streams 
    WHERE disconnected_at IS NOT NULL 
      AND disconnected_at < NOW() - INTERVAL '1 day';
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup (requires pg_cron extension)
-- Uncomment if pg_cron is available
-- SELECT cron.schedule('cleanup-event-data', '0 2 * * *', $$SELECT cleanup_old_event_data()$$);

-- Partitioning for events table (monthly partitions for better performance)
-- Function to create monthly event partitions
CREATE OR REPLACE FUNCTION create_monthly_event_partition()
RETURNS void AS $$
DECLARE
    start_date date;
    end_date date;
    partition_name text;
BEGIN
    start_date := date_trunc('month', CURRENT_DATE);
    end_date := start_date + interval '1 month';
    partition_name := 'events_' || to_char(start_date, 'YYYY_MM');
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF events
        FOR VALUES FROM (%L) TO (%L)', partition_name, start_date, end_date);
END;
$$ LANGUAGE plpgsql;

-- Schedule partition creation (requires pg_cron extension)
-- Uncomment if pg_cron is available
-- SELECT cron.schedule('create-event-partitions', '0 0 1 * *', $$SELECT create_monthly_event_partition()$$);