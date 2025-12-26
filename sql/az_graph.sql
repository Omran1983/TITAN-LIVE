-- =========================================================
-- AION-ZERO KNOWLEDGE GRAPH (GraphRAG)
-- Structured memory for dependency awareness and reasoning.
-- =========================================================

-- 1. Nodes (Entities)
-- e.g. "Jarvis-CodeAgent.ps1", "Supabase", "UserGuide.md"
create table if not exists public.az_graph_nodes (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,                 -- Unique identifier (e.g. filename or entity name)
  type        text not null,                 -- 'file', 'service', 'concept', 'agent'
  summary     text,                          -- LLM-generated summary
  meta        jsonb default '{}'::jsonb,     -- file_path, size, last_modified
  created_at  timestamptz default now(),
  updated_at  timestamptz default now(),
  unique(name, type)
);

-- 2. Edges (Relationships)
-- e.g. "Jarvis-CodeAgent" --(imports)--> "Jarvis-LoadEnv"
create table if not exists public.az_graph_edges (
  id          uuid primary key default gen_random_uuid(),
  source      text not null,                 -- az_graph_nodes.name
  target      text not null,                 -- az_graph_nodes.name
  relation    text not null,                 -- 'imports', 'calls', 'depends_on', 'relates_to'
  weight      numeric default 1.0,           -- relevance score
  meta        jsonb default '{}'::jsonb,     -- snippet evidence
  created_at  timestamptz default now(),
  unique(source, target, relation)
);

-- 3. Communities (Leiden/Louvain Clusters)
-- Hierarchical grouping of nodes
create table if not exists public.az_graph_communities (
  id          uuid primary key default gen_random_uuid(),
  level       integer not null default 0,    -- 0=atomic, 1=group, 2=domain
  title       text not null,                 -- "Auth Subsystem"
  summary     text,                          -- "Controls all login/security flows"
  node_ids    text[] default '{}',           -- Array of node names in this community
  created_at  timestamptz default now()
);

-- Indexes for fast retrieval
create index if not exists idx_graph_nodes_name on public.az_graph_nodes (name);
create index if not exists idx_graph_edges_source on public.az_graph_edges (source);
create index if not exists idx_graph_edges_target on public.az_graph_edges (target);
