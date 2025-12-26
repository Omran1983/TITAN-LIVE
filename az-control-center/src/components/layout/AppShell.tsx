import React from 'react';
import { TopNav } from './TopNav';
import { Sidebar } from './Sidebar';

interface AppShellProps {
  children: React.ReactNode;
}

export const AppShell: React.FC<AppShellProps> = ({ children }) => {
  return (
    <div className="app-shell">
      <TopNav />
      <Sidebar />
      <main className="main">{children}</main>
    </div>
  );
};
