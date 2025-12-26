import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabaseClient';
import type { AzHeartbeat, AzCommand, AzHealthSnapshot } from '../types/az';
import { StatCard } from '../components/shared/StatCard';

export const BrainstemPage: React.FC = () => {
  const [heartbeats, setHeartbeats] = useState<AzHeartbeat[]>([]);
  const [commands, setCommands] = useState<AzCommand[]>([]);
  const [health, setHealth] = useState<AzHealthSnapshot | null>(null);

  useEffect(() => {
    const fetchAll = async () => {
      const [hbRes, cmdRes, healthRes] = await Promise.all([
        supabase
          .from('az_heartbeats')
          .select('*')
          .order('ts', { ascending: false })
          .limit(20),
        supabase
          .from('az_commands')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(50),
        supabase
          .from('az_health_snapshots')
          .select('*')
          .order('ts', { ascending: false })
          .limit(1)
          .maybeSingle()
      ]);

      if (!hbRes.error && hbRes.data) setHeartbeats(hbRes.data as AzHeartbeat[]);
      if (!cmdRes.error && cmdRes.data) setCommands(cmdRes.data as AzCommand[]);
      if (!healthRes.error && healthRes.data)
        setHealth(healthRes.data as AzHealthSnapshot);
    };

    fetchAll();
  }, []);

  const inputsPerMin = commands.length;
  const outputsPerMin = commands.filter((c) => c.status === 'succeeded').length;

  return (
    <div>
      <h1 className="page-title">Brainstem</h1>
      <p className="page-subtitle">
        Heartbeat, breathing, reflexes and automatic life-support loops for AION-ZERO.
      </p>

      <div className="grid-3">
        <StatCard
          title="Queue Depth"
          value={health?.queue_depth ?? 0}
          subtext="From last health snapshot"
        />
        <StatCard
          title="Inputs (last window)"
          value={inputsPerMin}
          subtext="Commands created (placeholder metric)"
        />
        <StatCard
          title="Outputs (last window)"
          value={outputsPerMin}
          subtext="Commands succeeded (placeholder metric)"
        />
      </div>

      <div className="card mb-4">
        <div className="text-[13px] font-semibold mb-2">Heartbeat Timeline</div>
        <table className="table">
          <thead>
            <tr>
              <th>Time</th>
              <th>Agent</th>
              <th>Status</th>
              <th>Details</th>
            </tr>
          </thead>
          <tbody>
            {heartbeats.map((hb) => (
              <tr key={hb.id}>
                <td className="mono">{new Date(hb.ts).toLocaleString()}</td>
                <td className="table-row-muted">{hb.agent_id}</td>
                <td>{hb.status}</td>
                <td className="table-row-muted">
                  {hb.details ? JSON.stringify(hb.details) : '—'}
                </td>
              </tr>
            ))}
            {heartbeats.length === 0 && (
              <tr>
                <td colSpan={4} className="table-row-muted">
                  No heartbeat records yet. Once Atlas loop is wired, they will appear here.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="card">
        <div className="text-[13px] font-semibold mb-2">Command Flow (digest)</div>
        <table className="table">
          <thead>
            <tr>
              <th>Created</th>
              <th>Type</th>
              <th>Status</th>
              <th>Source → Target</th>
            </tr>
          </thead>
          <tbody>
            {commands.map((c) => (
              <tr key={c.id}>
                <td className="mono">{new Date(c.created_at).toLocaleString()}</td>
                <td>{c.type}</td>
                <td>{c.status}</td>
                <td className="table-row-muted">
                  {c.source_agent ?? '—'} → {c.target_agent ?? '—'}
                </td>
              </tr>
            ))}
            {commands.length === 0 && (
              <tr>
                <td colSpan={4} className="table-row-muted">
                  No commands yet. Once Sprint v1.0 begins emitting commands, they will appear.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
