import React from 'react';

interface StatCardProps {
  title: string;
  value: string | number;
  subtext?: string;
}

export const StatCard: React.FC<StatCardProps> = ({ title, value, subtext }) => {
  return (
    <div className="card">
      <div className="stat-title">{title}</div>
      <div className="stat-value">{value}</div>
      {subtext && <div className="stat-subtext">{subtext}</div>}
    </div>
  );
};
