import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabaseClient';
import type { AzHealthSnapshot } from '../../types/az';
import { StatusBadge } from '../shared/StatusBadge';

export const TopNav: React.FC = () => {
  const [health, setHealth] = useState<AzHealthSnapshot | null>(null);

  useEffect(() => {
    const fetchHealth = async () => {
      const { data, error } = await supabase
        .from('az_health_snapshots')
        .select('*')
        .order('ts', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (!error && data) setHealth(data as AzHealthSnapshot);
    };

    fetchHealth();
  }, []);

  const status = health?.overall_status ?? 'unknown';

  return (
    <header className="topnav">
      <div className="app-title">AION-ZERO · Control Center</div>
      <div className="topnav-status">
        <StatusBadge status={status} />
        {health ? (
          <span className="mono" style={{ fontSize: 11 }}>
            Last snapshot: {new Date(health.ts).toLocaleTimeString()}
          </span>
        ) : (
          <span style={{ fontSize: 11, color: '#9ca3af' }}>No health data</span>
        )}
      </div>
    </header>
  );
};
