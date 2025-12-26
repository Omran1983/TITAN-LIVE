
-- 🗺️ AZ ROADMAP: The implementation backlog
-- Stores the 47+ items user provided with full implementation context.

CREATE TABLE IF NOT EXISTS az_roadmap (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL, -- 'Core', 'Agents', 'Trading', 'Infra', 'Business', 'Data', 'Intel', 'Governance'
    title TEXT NOT NULL,
    description TEXT, -- "What it is"
    build_pieces TEXT, -- "Build pieces"
    interfaces TEXT, -- "Data/Interfaces"
    steps TEXT, -- "Implementation steps"
    done_condition TEXT, -- "Done when"
    status TEXT DEFAULT 'parked', -- 'parked', 'active', 'done'
    priority INTEGER DEFAULT 50, -- 1 (High) to 100 (Low)
    created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE az_roadmap ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow All" ON az_roadmap FOR ALL USING (true);
