-- Table to index the downloaded n8n workflows
CREATE TABLE IF NOT EXISTS az_n8n_workflows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filename TEXT NOT NULL,
    filepath TEXT NOT NULL,
    name TEXT, -- Extracted from JSON if available, or filename
    nodes JSONB, -- Storing node types/names for search
    credentials JSONB, -- Storing required credential types
    is_gold BOOLEAN DEFAULT false,
    tags TEXT[],
    ingested_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for searching nodes/creds
CREATE INDEX IF NOT EXISTS idx_n8n_nodes ON az_n8n_workflows USING gin (nodes);
CREATE INDEX IF NOT EXISTS idx_n8n_creds ON az_n8n_workflows USING gin (credentials);
