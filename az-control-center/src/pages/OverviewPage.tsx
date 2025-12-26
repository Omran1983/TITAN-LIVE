import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabaseClient';
import type { AzAgent, AzHealthSnapshot, AzCommand, AzEvent } from '../types/az';
import { StatCard } from '../components/shared/StatCard';
import { StatusBadge } from '../components/shared/StatusBadge';

export const OverviewPage: React.FC = () => {
  const [agents, setAgents] = useState<AzAgent[]>([]);
  const [health, setHealth] = useState<AzHealthSnapshot | null>(null);
  const [commands, setCommands] = useState<AzCommand[]>([]);
  const [events, setEvents] = useState<AzEvent[]>([]);

  useEffect(() => {
    const fetchAll = async () => {
      const [agentsRes, healthRes, commandsRes, eventsRes] = await Promise.all([
        supabase.from('az_agents').select('*'),
        supabase
          .from('az_health_snapshots')
          .select('*')
          .order('ts', { ascending: false })
          .limit(1)
          .maybeSingle(),
        supabase.from('az_commands').select('*').order('created_at', { ascending: false }).limit(50),
        supabase
          .from('az_events')
          .select('*')
          .order('ts', { ascending: false })
          .limit(20)
      ]);

      if (!agentsRes.error && agentsRes.data) setAgents(agentsRes.data as AzAgent[]);
      if (!healthRes.error && healthRes.data) setHealth(healthRes.data as AzHealthSnapshot);
      if (!commandsRes.error && commandsRes.data)
        setCommands(commandsRes.data as AzCommand[]);
      if (!eventsRes.error && eventsRes.data) setEvents(eventsRes.data as AzEvent[]);
    };

    fetchAll();
  }, []);

  const queuePending = commands.filter((c) => c.status === 'queued').length;
  const queueRunning = commands.filter((c) => c.status === 'running').length;
  const queueDone = commands.filter((c) => c.status === 'succeeded').length;

  return (
    <div>
      <h1 className="page-title">System Overview</h1>
      <p className="page-subtitle">High-level health and Quadrant status for AION-ZERO.</p>

      <div className="grid-3">
        <StatCard
          title="Queue Pending"
          value={queuePending}
          subtext="Commands waiting to be executed"
        />
        <StatCard
          title="Queue Running"
          value={queueRunning}
          subtext="Currently executing commands"
        />
        <StatCard
          title="Queue Completed"
          value={queueDone}
          subtext="Succeeded commands (last 50)"
        />
      </div>

      <div className="card" style={{ marginBottom: 16 }}>
        <div className="flex-between" style={{ marginBottom: 8 }}>
          <div style={{ fontSize: 13, fontWeight: 600 }}>Quadrant Status</div>
        </div>
        <table className="table">
          <thead>
            <tr>
              <th>Agent</th>
              <th>Role</th>
              <th>Status</th>
              <th>Last Heartbeat</th>
            </tr>
          </thead>
          <tbody>
            {agents.map((a) => (
              <tr key={a.id}>
                <td style={{ fontWeight: 500, textTransform: 'capitalize' }}>{a.name}</td>
                <td>{a.role}</td>
                <td>
                  <StatusBadge status={a.status} />
                </td>
                <td className="mono table-row-muted">
                  {a.last_heartbeat_at
                    ? new Date(a.last_heartbeat_at).toLocaleTimeString()
                    : '—'}
                </td>
              </tr>
            ))}
            {agents.length === 0 && (
              <tr>
                <td colSpan={4} className="table-row-muted">
                  No agents found. Seed az_agents to see data.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="card">
        <div className="flex-between" style={{ marginBottom: 8 }}>
          <div style={{ fontSize: 13, fontWeight: 600 }}>Recent Autonomic Events</div>
        </div>
        <table className="table">
          <thead>
            <tr>
              <th>Time</th>
              <th>Source</th>
              <th>Type</th>
              <th>Severity</th>
              <th>Summary</th>
            </tr>
          </thead>
          <tbody>
            {events.map((e) => (
              <tr key={e.id}>
                <td className="mono">{new Date(e.ts).toLocaleTimeString()}</td>
                <td>{e.source}</td>
                <td>{e.event_type}</td>
                <td>
                  <span className="chip">{e.severity}</span>
                </td>
                <td className="table-row-muted">
                  {e.payload && e.payload['summary']
                    ? String(e.payload['summary'])
                    : JSON.stringify(e.payload ?? {})}
                </td>
              </tr>
            ))}
            {events.length === 0 && (
              <tr>
                <td colSpan={5} className="table-row-muted">
                  No events logged yet. Once Sprint v1.0 runs, this will fill with activity.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
