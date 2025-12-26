// src/components/layout/Header.jsx
import React from 'react';

export function Header({ title, subtitle }) {
  return (
    <header
      style={{
        padding: '16px 20px',
        borderBottom: '1px solid #e5e7eb',
        background: '#f9fafb',
      }}
    >
      <div style={{ fontSize: 20, fontWeight: 600 }}>{title}</div>
      {subtitle && (
        <div style={{ fontSize: 13, color: '#6b7280', marginTop: 4 }}>{subtitle}</div>
      )}
    </header>
  );
}
