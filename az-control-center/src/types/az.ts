// src/types/az.ts
export type AzAgentKey = 'helix' | 'atlas' | 'specter' | 'nova' | string;

export interface AzAgent {
  id: string | number;
  key: AzAgentKey;
  name: string;
  role: string;
  status: 'active' | 'idle' | 'degraded' | 'offline' | string;
  current_task_id: string | number | null;
  last_heartbeat_at: string | null;
  meta: Record<string, unknown> | null;
}

export interface AzHealthSnapshot {
  id: string | number;
  ts: string;
  overall_status: string;
  queue_depth: number | null;
  errors_last_10m: number | null;
  avg_latency_ms: number | null;
  meta: Record<string, unknown> | null;
}

export type AzEventSeverity = 'info' | 'warn' | 'error' | 'critical' | string;

export interface AzEvent {
  id: string | number;
  ts: string;
  source: string;
  event_type: string;
  severity: AzEventSeverity;
  command_id: string | number | null;
  from_agent: string | null;
  to_agent: string | null;
  payload: Record<string, unknown> | null;
  correlation_id: string | null;
}

export interface AzHeartbeat {
  id: string | number;
  agent_id: string | number;
  ts: string;
  status: string;
  details: Record<string, unknown> | null;
}

export interface AzCommand {
  id: string | number;
  type: string;
  status: string;
  priority: number | null;
  payload: Record<string, unknown> | null;
  created_at: string;
  picked_at: string | null;
  completed_at: string | null;
  error_id: string | number | null;
  source_agent: string | null;
  target_agent: string | null;
}

export interface AzNeuron {
  id: string | number;
  ts: string;
  source_agent: string;
  target_agent: string;
  signal_type: string;
  payload: Record<string, unknown> | null;
}
