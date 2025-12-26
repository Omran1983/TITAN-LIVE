// src/components/dashboard/KpiCards.jsx
import React from 'react';

export function KpiCards({ kpis, loading }) {
  const items = [
    {
      key: 'total_employers',
      label: 'Employers',
    },
    {
      key: 'total_workers',
      label: 'Workers',
    },
    {
      key: 'total_leads',
      label: 'Leads',
    },
    {
      key: 'total_requests',
      label: 'Requests',
    },
    {
      key: 'active_requests',
      label: 'Active requests',
    },
    {
      key: 'workers_requested',
      label: 'Workers requested',
    },
    {
      key: 'workers_fulfilled',
      label: 'Workers fulfilled',
    },
    {
      key: 'dorm_capacity',
      label: 'Dorm capacity',
    },
    {
      key: 'dorm_occupied',
      label: 'Dorm occupied',
    },
  ];

  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
        gap: 12,
        marginBottom: 20,
      }}
    >
      {items.map((item) => {
        const value = kpis ? kpis[item.key] : null;
        return (
          <div
            key={item.key}
            style={{
              padding: '10px 12px',
              borderRadius: 10,
              border: '1px solid #e5e7eb',
              background: '#ffffff',
              display: 'flex',
              flexDirection: 'column',
              gap: 6,
            }}
          >
            <div style={{ fontSize: 11, color: '#6b7280', textTransform: 'uppercase' }}>
              {item.label}
            </div>
            <div style={{ fontSize: 20, fontWeight: 600 }}>
              {loading ? '…' : value ?? '—'}
            </div>
          </div>
        );
      })}
    </div>
  );
}
