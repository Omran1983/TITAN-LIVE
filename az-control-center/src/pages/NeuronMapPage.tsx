// src/pages/NeuronMapPage.tsx
import React, { useEffect, useMemo, useState } from 'react';
import { StatCard } from '../components/shared/StatCard';
import { supabase } from '../lib/supabaseClient';
import type { AzNeuron } from '../types/az';

export const NeuronMapPage: React.FC = () => {
  const [neurons, setNeurons] = useState<AzNeuron[]>([]);

  useEffect(() => {
    const fetchNeurons = async () => {
      const { data, error } = await supabase
        .from('az_neurons')
        .select('*')
        .order('ts', { ascending: false })
        .limit(200);

      if (!error && data) {
        setNeurons(data as AzNeuron[]);
      }
    };

    fetchNeurons();
  }, []);

  const { agents, matrix, totalSignals, distinctRoutes, lastSignalTs } = useMemo(() => {
    const aSet = new Set<string>();
    neurons.forEach((n) => {
      aSet.add(n.source_agent);
      aSet.add(n.target_agent);
    });
    const agents = Array.from(aSet).sort();

    const matrix: Record<string, Record<string, number>> = {};
    agents.forEach((from) => {
      matrix[from] = {};
      agents.forEach((to) => {
        matrix[from][to] = 0;
      });
    });

    neurons.forEach((n) => {
      if (!matrix[n.source_agent]) matrix[n.source_agent] = {};
      if (matrix[n.source_agent][n.target_agent] == null) {
        matrix[n.source_agent][n.target_agent] = 0;
      }
      matrix[n.source_agent][n.target_agent] += 1;
    });

    const totalSignals = neurons.length;
    const distinctRoutes = neurons.reduce((acc, n) => {
      acc.add(`${n.source_agent}→${n.target_agent}`);
      return acc;
    }, new Set<string>()).size;

    const lastSignalTs = neurons[0]?.ts ?? null;

    return { agents, matrix, totalSignals, distinctRoutes, lastSignalTs };
  }, [neurons]);

  return (
    <div>
      <h1 className="page-title">Neuron Map</h1>
      <p className="page-subtitle">
        How agents talk to each other: signals, routes and cross-talk across AION-ZERO.
      </p>

      <div className="grid-3">
        <StatCard
          title="Signals (loaded)"
          value={totalSignals}
          subtext="Rows in az_neurons (last 200)"
        />
        <StatCard
          title="Distinct Routes"
          value={distinctRoutes}
          subtext="Unique source → target paths"
        />
        <StatCard
          title="Last Signal"
          value={lastSignalTs ? new Date(lastSignalTs).toLocaleTimeString() : '—'}
          subtext="Most recent neuron firing"
        />
      </div>

      <div className="card mb-4">
        <div className="flex-between mb-2">
          <div className="text-[13px] font-semibold">Neuron Adjacency Matrix</div>
          <div className="text-[11px] text-gray-500">
            Cells show how many signals flowed from one agent to another.
          </div>
        </div>

        {agents.length === 0 ? (
          <div className="table-row-muted py-2">
            No neuron data yet. Once agents start emitting signals to az_neurons, this map will
            light up.
          </div>
        ) : (
          <table className="table">
            <thead>
              <tr>
                <th>From \ To</th>
                {agents.map((a) => (
                  <th key={a}>{a}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {agents.map((from) => (
                <tr key={from}>
                  <td className="font-medium">{from}</td>
                  {agents.map((to) => {
                    const count = matrix[from]?.[to] ?? 0;
                    return (
                      <td key={to} className={count === 0 ? 'table-row-muted' : ''}>
                        {count === 0 ? '·' : count}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <div className="card">
        <div className="flex-between mb-2">
          <div className="text-[13px] font-semibold">Recent Signals</div>
          <div className="text-[11px] text-gray-500">
            Latest messages moving along the neural pathways.
          </div>
        </div>
        <table className="table">
          <thead>
            <tr>
              <th>Time</th>
              <th>Source → Target</th>
              <th>Type</th>
              <th>Summary</th>
            </tr>
          </thead>
          <tbody>
            {neurons.map((n) => (
              <tr key={n.id}>
                <td className="mono">{new Date(n.ts).toLocaleString()}</td>
                <td>
                  {n.source_agent} → {n.target_agent}
                </td>
                <td>
                  <span className="chip">{n.signal_type}</span>
                </td>
                <td className="table-row-muted">
                  {n.payload && n.payload['summary']
                    ? String(n.payload['summary'])
                    : JSON.stringify(n.payload ?? {})}
                </td>
              </tr>
            ))}
            {neurons.length === 0 && (
              <tr>
                <td colSpan={4} className="table-row-muted">
                  No signals yet. Once AZ agents start emitting to az_neurons, you&apos;ll see the
                  brain&apos;s traffic here.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
