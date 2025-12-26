
-- 🦅 AZ MISSION RUNS: The "Scar Tissue" of the System
-- Stores the history of every authorized mission executed by the Governor.

CREATE TABLE IF NOT EXISTS az_mission_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mission_name TEXT NOT NULL,
    start_ts TIMESTAMPTZ NOT NULL DEFAULT now(),
    end_ts TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'running', -- running, success, failed, aborted, timeout, panic
    baseline_val INTEGER,
    final_val INTEGER,
    gained_val INTEGER,
    command_executed TEXT,
    kill_reason TEXT,
    log_file_path TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for quick lookup of recent missions
CREATE INDEX IF NOT EXISTS idx_mission_runs_ts ON az_mission_runs(start_ts DESC);

-- RLS: Allow Reader access (Internal only)
ALTER TABLE az_mission_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow Internal Read" ON az_mission_runs
    FOR SELECT TO authenticated, anon
    USING (true);

CREATE POLICY "Allow Internal Write" ON az_mission_runs
    FOR INSERT TO authenticated, anon
    WITH CHECK (true);

CREATE POLICY "Allow Internal Update" ON az_mission_runs
    FOR UPDATE TO authenticated, anon
    USING (true);
