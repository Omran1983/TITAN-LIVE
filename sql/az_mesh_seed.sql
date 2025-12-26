-- JARVIS MESH: INITIAL SEED DATA
-- "The Map" of the Network

-- 1. REGISTER AGENTS
insert into az_mesh_agents (agent_name, description) values
('Jarvis-Brain', 'The Central Reasoning Engine (Python/Flask)'),
('Jarvis-CodeAgent', 'The Engineering Arm (PowerShell)'),
('Jarvis-Watchdog', 'System Health Monitor'),
('Jarvis-CommandsApi', 'Legacy Command Interface')
on conflict (agent_name) do nothing;

-- 2. REGISTER ENDPOINTS (Localhost Defaults)
-- Note: Ports must match your actual running aservices
insert into az_mesh_endpoints (agent_name, endpoint_url) values
('Jarvis-Brain', 'http://127.0.0.1:5000/api/execute'), -- The Brain's Ear
('Jarvis-CodeAgent', 'http://127.0.0.1:5001/webhook')   -- Future CodeAgent API
on conflict do nothing;

-- 3. REGISTER ROUTES (The Allow-List)
insert into az_mesh_routes (source_agent, target_agent, route_key, max_retries, timeout_ms) values
-- Brain controlling CodeAgent
('Jarvis-Brain', 'Jarvis-CodeAgent', 'code.execute', 3, 60000),
('Jarvis-Brain', 'Jarvis-CodeAgent', 'code.read', 3, 10000),

-- Watchdog alerting Brain
('Jarvis-Watchdog', 'Jarvis-Brain', 'alert.critical', 5, 5000)
on conflict do nothing;
