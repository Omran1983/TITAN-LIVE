// src/pages/ReflexesPage.tsx
import React, { useEffect, useState } from 'react';
import { StatCard } from '../components/shared/StatCard';
import { supabase } from '../lib/supabaseClient';

interface ReflexRule {
  id: number;
  name: string;
  description: string | null;
  enabled: boolean;
  trigger_type: string;
  trigger_params: Record<string, unknown> | null;
  action_type: string;
  action_params: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
}

interface ReflexFiring {
  id: number;
  rule_id: number;
  ts: string;
  status: string;
  agent: string | null;
  command_id: string | null;
  details: Record<string, unknown> | null;
}

export const ReflexesPage: React.FC = () => {
  const [rules, setRules] = useState<ReflexRule[]>([]);
  const [firings, setFirings] = useState<ReflexFiring[]>([]);

  useEffect(() => {
    const load = async () => {
      const [rulesRes, fireRes] = await Promise.all([
        supabase.from('az_reflex_rules').select('*').order('id', { ascending: true }),
        supabase
          .from('az_reflex_firings')
          .select('*')
          .order('ts', { ascending: false })
          .limit(100),
      ]);

      if (!rulesRes.error && rulesRes.data) {
        setRules(rulesRes.data as ReflexRule[]);
      }
      if (!fireRes.error && fireRes.data) {
        setFirings(fireRes.data as ReflexFiring[]);
      }
    };

    load();
  }, []);

  const enabledCount = rules.filter((r) => r.enabled).length;

  return (
    <div>
      <h1 className="page-title">Reflex Engine</h1>
      <p className="page-subtitle">
        Automatic reactions handled by Atlas and friends: what the system does on its own, and when.
      </p>

      <div className="grid-3">
        <StatCard
          title="Reflex Rules"
          value={rules.length}
          subtext={`${enabledCount} enabled`}
        />
        <StatCard
          title="Recent Firings"
          value={firings.length}
          subtext="Last 100 reflex events"
        />
        <StatCard
          title="Last Firing"
          value={
            firings[0]
              ? new Date(firings[0].ts).toLocaleTimeString()
              : '—'
          }
          subtext="Most recent reflex execution"
        />
      </div>

      <div className="card" style={{ marginBottom: 16 }}>
        <div className="flex-between" style={{ marginBottom: 8 }}>
          <div style={{ fontSize: 13, fontWeight: 600 }}>Reflex Rules</div>
          <div style={{ fontSize: 11, color: '#6b7280' }}>
            Guardrails that keep AION-ZERO healthy without manual intervention.
          </div>
        </div>
        <table className="table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Rule</th>
              <th>Trigger</th>
              <th>Action</th>
              <th>Enabled</th>
            </tr>
          </thead>
          <tbody>
            {rules.map((r) => (
              <tr key={r.id}>
                <td className="mono">{r.id}</td>
                <td>
                  <div style={{ fontWeight: 500 }}>{r.name}</div>
                  <div className="table-row-muted" style={{ fontSize: 12 }}>
                    {r.description}
                  </div>
                </td>
                <td>
                  <div className="chip">{r.trigger_type}</div>
                  <div className="table-row-muted" style={{ fontSize: 11 }}>
                    {JSON.stringify(r.trigger_params ?? {})}
                  </div>
                </td>
                <td>
                  <div className="chip">{r.action_type}</div>
                  <div className="table-row-muted" style={{ fontSize: 11 }}>
                    {JSON.stringify(r.action_params ?? {})}
                  </div>
                </td>
                <td>
                  <span className={`chip ${r.enabled ? '' : 'chip-muted'}`}>
                    {r.enabled ? 'on' : 'off'}
                  </span>
                </td>
              </tr>
            ))}
            {rules.length === 0 && (
              <tr>
                <td colSpan={5} className="table-row-muted">
                  No reflex rules yet. Use AZ agents to insert into <code>az_reflex_rules</code> and
                  they will show here.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="card">
        <div className="flex-between" style={{ marginBottom: 8 }}>
          <div style={{ fontSize: 13, fontWeight: 600 }}>Recent Reflex Firings</div>
          <div style={{ fontSize: 11, color: '#6b7280' }}>
            When rules triggered, which agent executed them and what happened.
          </div>
        </div>
        <table className="table">
          <thead>
            <tr>
              <th>Time</th>
              <th>Rule ID</th>
              <th>Status</th>
              <th>Agent</th>
              <th>Details</th>
            </tr>
          </thead>
          <tbody>
            {firings.map((f) => (
              <tr key={f.id}>
                <td className="mono">
                  {new Date(f.ts).toLocaleTimeString()}
                </td>
                <td className="mono">{f.rule_id}</td>
                <td>
                  <span className="chip">{f.status}</span>
                </td>
                <td>{f.agent ?? '—'}</td>
                <td className="table-row-muted">
                  {f.details ? JSON.stringify(f.details) : '—'}
                </td>
              </tr>
            ))}
            {firings.length === 0 && (
              <tr>
                <td colSpan={5} className="table-row-muted">
                  No reflex firings yet. Once Atlas/Helix start evaluating rules, their actions will
                  appear here.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
