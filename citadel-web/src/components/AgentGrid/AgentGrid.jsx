import React from 'react';
import { Card, CardTitle, CardContent, CardHeader } from '../ui/Card';
import { Bot, Terminal, Eye, Brain, Activity } from 'lucide-react';
import { useAgents } from '../../hooks/useAgents';

// Map string roles/names to Icons
const ICON_MAP = {
    'builder': Terminal,
    'supervisor': Eye,
    'intelligence': Brain,
    'ops': Bot,
    'default': Activity
};

export function AgentGrid() {
    const { agents, isLoading } = useAgents();

    // Fallback if DB is empty (Post-migration state)
    const displayAgents = agents.length > 0 ? agents : [
        { name: 'Jarvis-CodeAgent', role: 'builder', status: 'connecting...', id: 'stub-1' },
        { name: 'Jarvis-Watchdog', role: 'supervisor', status: 'connecting...', id: 'stub-2' },
        { name: 'Jarvis-Brain', role: 'intelligence', status: 'connecting...', id: 'stub-3' },
    ];

    if (isLoading) {
        return <div className="text-slate-500 font-mono text-xs animate-pulse">Scanbus: Scanning Mesh Network...</div>;
    }

    return (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {displayAgents.map((agent) => {
                // Resolve Icon
                const roleKey = (agent.role || 'default').toLowerCase();
                const Icon = ICON_MAP[roleKey] || ICON_MAP['default'];

                // Resolve Color based on Status
                const status = (agent.status || 'offline').toLowerCase();
                let color = 'text-slate-400';
                if (status === 'active' || status === 'running') color = 'text-emerald-400';
                if (status === 'thinking' || status === 'working') color = 'text-purple-400';
                if (status === 'idle') color = 'text-sky-400';
                if (status === 'error' || status === 'down') color = 'text-rose-400';

                return (
                    <Card key={agent.id || agent.name} className="relative overflow-hidden group">
                        <div className={`absolute top-0 right-0 p-3 opacity-20 ${color}`}>
                            <Icon className="w-16 h-16 -mr-4 -mt-4 transform rotate-12 group-hover:rotate-0 transition-transform" />
                        </div>

                        <CardHeader className="pb-2">
                            <CardTitle className="text-sm font-mono text-slate-400 uppercase">{agent.role || 'Agent'}</CardTitle>
                            <div className={`text-lg font-bold ${color}`}>{agent.name}</div>
                        </CardHeader>

                        <CardContent>
                            <div className="flex items-center justify-between text-xs mt-2">
                                <span className="text-slate-500">STATUS</span>
                                <span className={`px-2 py-0.5 rounded-full uppercase font-bold tracking-wide border border-white/5 
                  ${status === 'active' || status === 'running' ? 'bg-emerald-500/20 text-emerald-400' : ''}
                  ${status === 'idle' ? 'bg-sky-900/20 text-sky-300' : ''}
                  ${status === 'thinking' ? 'bg-purple-500/20 text-purple-400' : ''}
                  ${status === 'offline' || status === 'down' ? 'bg-rose-900/20 text-rose-700' : ''}
                `}>
                                    {status}
                                </span>
                            </div>
                            {/* Health Bar */}
                            <div className="w-full bg-slate-800 h-1 mt-4 rounded-full overflow-hidden">
                                <div
                                    className={`h-full opacity-50 ${color.replace('text', 'bg')}`}
                                    style={{ width: status === 'offline' ? '0%' : '100%' }}
                                ></div>
                            </div>
                        </CardContent>
                    </Card>
                );
            })}
        </div>
    );
}
