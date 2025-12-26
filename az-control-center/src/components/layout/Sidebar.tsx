// src/components/layout/Sidebar.tsx
import React from 'react';
import { NavLink } from 'react-router-dom';

const linkClass = ({ isActive }: { isActive: boolean }) =>
  'sidebar-link' + (isActive ? ' active' : '');

export const Sidebar: React.FC = () => {
  return (
    <aside className="sidebar">
      <div className="sidebar-section-title">Core</div>
      <NavLink to="/console" className={linkClass}>
        TITAN <span className="text-[10px] bg-green-500/20 text-green-400 px-1 rounded ml-2 border border-green-500/30">CONSOLE</span>
      </NavLink>
      <NavLink to="/" className={linkClass}>
        Overview
      </NavLink>
      <NavLink to="/brainstem" className={linkClass}>
        Brainstem
      </NavLink>
      <NavLink to="/neuron-map" className={linkClass}>
        Neuron Map
      </NavLink>
      <NavLink to="/reflexes" className={linkClass}>
        Reflex Engine
      </NavLink>
      <NavLink to="/logs" className={linkClass}>
        Logs
      </NavLink>

      <div className="sidebar-section-title">Marketplace</div>
      <NavLink to="/library" className={linkClass}>
        Library <span className="text-[10px] bg-blue-100 text-blue-700 px-1 rounded ml-2">NEW</span>
      </NavLink>

      <div className="sidebar-section-title">System</div>
      <NavLink to="/system" className={linkClass}>
        System
      </NavLink>
      <NavLink to="/agents" className={linkClass}>
        Agents
      </NavLink>
      <NavLink to="/tools" className={linkClass}>
        Tools
      </NavLink>
      <NavLink to="/health" className={linkClass}>
        Health
      </NavLink>
      <NavLink to="/config" className={linkClass}>
        Config
      </NavLink>
    </aside>
  );
};
