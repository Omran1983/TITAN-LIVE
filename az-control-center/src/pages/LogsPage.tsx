import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabaseClient';
import type { AzEvent } from '../types/az';

export const LogsPage: React.FC = () => {
  const [events, setEvents] = useState<AzEvent[]>([]);
  const [agentFilter, setAgentFilter] = useState<string>('all');
  const [severityFilter, setSeverityFilter] = useState<string>('all');

  useEffect(() => {
    const fetchEvents = async () => {
      const { data, error } = await supabase
        .from('az_events')
        .select('*')
        .order('ts', { ascending: false })
        .limit(100);

      if (!error && data) setEvents(data as AzEvent[]);
    };

    fetchEvents();
  }, []);

  const filtered = events.filter((e) => {
    if (agentFilter !== 'all' && e.source !== agentFilter) return false;
    if (severityFilter !== 'all' && e.severity !== severityFilter) return false;
    return true;
  });

  return (
    <div>
      <h1 className="page-title">Autonomic Logs</h1>
      <p className="page-subtitle">
        Raw, chronological trace of AION-ZERO internal events, signals and reflexes.
      </p>

      <div className="card" style={{ marginBottom: 12 }}>
        <div className="flex" style={{ justifyContent: 'space-between' }}>
          <div style={{ fontSize: 13, fontWeight: 600 }}>Filters</div>
          <div className="flex">
            <select
              value={agentFilter}
              onChange={(e) => setAgentFilter(e.target.value)}
              style={{ fontSize: 12, padding: '4px 6px', borderRadius: 8 }}
            >
              <option value="all">All agents</option>
              <option value="helix">Helix</option>
              <option value="atlas">Atlas</option>
              <option value="specter">Specter</option>
              <option value="nova">Nova</option>
              <option value="system">System</option>
            </select>
            <select
              value={severityFilter}
              onChange={(e) => setSeverityFilter(e.target.value)}
              style={{ fontSize: 12, padding: '4px 6px', borderRadius: 8 }}
            >
              <option value="all">All severities</option>
              <option value="info">Info</option>
              <option value="warn">Warn</option>
              <option value="error">Error</option>
              <option value="critical">Critical</option>
            </select>
          </div>
        </div>
      </div>

      <div className="card">
        <table className="table">
          <thead>
            <tr>
              <th>Time</th>
              <th>Source</th>
              <th>Type</th>
              <th>Severity</th>
              <th>Payload</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((e) => (
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
            {filtered.length === 0 && (
              <tr>
                <td colSpan={5} className="table-row-muted">
                  No events match the filters. Once AZ starts logging, this view will come alive.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
