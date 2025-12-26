-- SMS Marketing System for AION-ZERO / TITAN OS
-- Database Schema Migration
-- Run this in your Supabase SQL Editor

-- ============================================
-- SMS CAMPAIGNS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS sms_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'draft', -- draft, sending, completed, failed
    total_recipients INTEGER DEFAULT 0,
    created_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    scheduled_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- ============================================
-- SMS MESSAGES TABLE (Individual Tracking)
-- ============================================
CREATE TABLE IF NOT EXISTS sms_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES sms_campaigns(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, sent, delivered, failed
    gateway_message_id VARCHAR(255),
    error_message TEXT,
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- ============================================
-- SMS CONTACTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS sms_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(255),
    email VARCHAR(255),
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    opted_in BOOLEAN DEFAULT true,
    source VARCHAR(100), -- csv_import, manual, order, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- ============================================
-- SMS TEMPLATES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS sms_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    category VARCHAR(100), -- marketing, transactional, notification
    variables TEXT[] DEFAULT ARRAY[]::TEXT[], -- e.g., ['name', 'order_number']
    created_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- ============================================
-- SMS GATEWAY CONFIGURATION TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS sms_gateway_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gateway_type VARCHAR(50) NOT NULL, -- sms_gateway_api, twilio, africas_talking
    api_url TEXT,
    api_key TEXT,
    device_id VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    rate_limit_ms INTEGER DEFAULT 1000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    config JSONB DEFAULT '{}'::jsonb
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_sms_messages_campaign_id ON sms_messages(campaign_id);
CREATE INDEX IF NOT EXISTS idx_sms_messages_phone ON sms_messages(phone_number);
CREATE INDEX IF NOT EXISTS idx_sms_messages_status ON sms_messages(status);
CREATE INDEX IF NOT EXISTS idx_sms_contacts_phone ON sms_contacts(phone_number);
CREATE INDEX IF NOT EXISTS idx_sms_contacts_opted_in ON sms_contacts(opted_in);
CREATE INDEX IF NOT EXISTS idx_sms_campaigns_status ON sms_campaigns(status);

-- ============================================
-- CAMPAIGN SUMMARY VIEW
-- ============================================
CREATE OR REPLACE VIEW sms_campaign_summary AS
SELECT 
    c.id,
    c.name,
    c.message,
    c.status,
    c.total_recipients,
    c.created_by,
    c.created_at,
    c.scheduled_at,
    c.completed_at,
    COUNT(m.id) FILTER (WHERE m.status = 'delivered') AS delivered_count,
    COUNT(m.id) FILTER (WHERE m.status = 'failed') AS failed_count,
    COUNT(m.id) FILTER (WHERE m.status = 'sent') AS sent_count,
    ROUND(
        (COUNT(m.id) FILTER (WHERE m.status = 'delivered')::NUMERIC / 
         NULLIF(c.total_recipients, 0) * 100), 
        2
    ) AS delivery_rate
FROM sms_campaigns c
LEFT JOIN sms_messages m ON c.id = m.campaign_id
GROUP BY c.id, c.name, c.message, c.status, c.total_recipients, 
         c.created_by, c.created_at, c.scheduled_at, c.completed_at
ORDER BY c.created_at DESC;

-- ============================================
-- STORED FUNCTION: Update Campaign Stats
-- ============================================
CREATE OR REPLACE FUNCTION update_campaign_stats(p_campaign_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE sms_campaigns
    SET total_recipients = (
        SELECT COUNT(*) 
        FROM sms_messages 
        WHERE campaign_id = p_campaign_id
    )
    WHERE id = p_campaign_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE sms_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_gateway_config ENABLE ROW LEVEL SECURITY;

-- Policies for authenticated users (admin access)
CREATE POLICY "Allow all for authenticated users" ON sms_campaigns
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all for authenticated users" ON sms_messages
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all for authenticated users" ON sms_contacts
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all for authenticated users" ON sms_templates
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all for authenticated users" ON sms_gateway_config
    FOR ALL USING (auth.role() = 'authenticated');

-- ============================================
-- TABLE COMMENTS (Documentation)
-- ============================================
COMMENT ON TABLE sms_campaigns IS 'SMS marketing campaigns management';
COMMENT ON TABLE sms_messages IS 'Individual SMS message tracking and delivery status';
COMMENT ON TABLE sms_contacts IS 'Contact database for SMS marketing with opt-in/opt-out tracking';
COMMENT ON TABLE sms_templates IS 'Reusable SMS message templates with variable substitution';
COMMENT ON TABLE sms_gateway_config IS 'SMS gateway configuration (Android phone, Twilio, Africa''s Talking, etc.)';

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================
-- Insert a sample template
INSERT INTO sms_templates (name, message, category, variables) VALUES
('Order Confirmation', 'Hi {{name}}, your order #{{order_number}} has been confirmed! Track at {{url}}', 'transactional', ARRAY['name', 'order_number', 'url'])
ON CONFLICT DO NOTHING;

-- Insert sample gateway config (update with your credentials)
INSERT INTO sms_gateway_config (gateway_type, api_url, is_active) VALUES
('sms_gateway_api', 'https://smsgateway.me/api/v4', false)
ON CONFLICT DO NOTHING;
