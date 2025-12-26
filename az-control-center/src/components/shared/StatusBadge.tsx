import React from 'react';

interface StatusBadgeProps {
  status: string;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status }) => {
  const s = status.toLowerCase();

  let cls = 'badge badge-amber';
  let label = status;

  if (s === 'ok' || s === 'good' || s === 'healthy' || s === 'active') {
    cls = 'badge badge-green';
  } else if (s === 'error' || s === 'critical' || s === 'down') {
    cls = 'badge badge-red';
  }

  if (!label) label = 'unknown';

  return <span className={cls}>{label}</span>;
};
