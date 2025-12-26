// src/components/layout/Sidebar.jsx
import React from 'react';

const navItems = [
  { key: 'dashboard', label: 'Dashboard' },
  { key: 'employers', label: 'Employers' },
  { key: 'workers', label: 'Workers' },
  { key: 'agents', label: 'Agents' },
  { key: 'dormitories', label: 'Dormitories' },
  { key: 'requests', label: 'Requests & Assignments' },
  { key: 'contracts', label: 'Contracts & Finance' },
];

export function Sidebar({ active, onChange }) {
  return (
    <aside
      style={{
        width: 240,
        background: '#020617',
        color: '#e5e7eb',
        display: 'flex',
        flexDirection: 'column',
        padding: '16px',
        boxSizing: 'border-box',
      }}
    >
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 18, fontWeight: 700 }}>ReachX · Board</div>
        <div style={{ fontSize: 12, color: '#9ca3af' }}>Jarvis Control Surface</div>
      </div>

      <nav style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {navItems.map((item) => {
          const isActive = item.key === active;
          return (
            <button
              key={item.key}
              onClick={() => onChange(item.key)}
              style={{
                textAlign: 'left',
                padding: '8px 10px',
                borderRadius: 6,
                border: 'none',
                cursor: 'pointer',
                fontSize: 13,
                background: isActive ? '#111827' : 'transparent',
                color: isActive ? '#f9fafb' : '#9ca3af',
              }}
            >
              {item.label}
            </button>
          );
        })}
      </nav>

      <div style={{ flexGrow: 1 }} />

      <div
        style={{
          fontSize: 11,
          color: '#6b7280',
          borderTop: '1px solid #111827',
          paddingTop: 8,
          marginTop: 8,
        }}
      >
        Status: <span style={{ color: '#22c55e' }}>Engine online</span>
      </div>
    </aside>
  );
}
