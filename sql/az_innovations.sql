
-- 🧠 AZ INNOVATIONS: The R&D Backlog
-- Stores technologies, libraries, and concepts the system has "Scouted" for self-improvement.

CREATE TABLE IF NOT EXISTS az_innovations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    category TEXT NOT NULL, -- 'AI', 'Storage', 'Code', 'Infrastructure'
    description TEXT,
    scouted_at TIMESTAMPTZ DEFAULT now(),
    status TEXT DEFAULT 'new', -- 'new', 'analyzing', 'rejected', 'adopted'
    compatibility_score INTEGER DEFAULT 0 -- 0-100 estimate of how easy it is to plug in
);

-- Index to avoid duplicate URLs
CREATE UNIQUE INDEX IF NOT EXISTS idx_innovations_url ON az_innovations(url);

-- RLS
ALTER TABLE az_innovations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow All" ON az_innovations FOR ALL USING (true);
