import React, { useState } from 'react';
import { Terminal, Send, Zap } from 'lucide-react';
import { Card } from '../ui/Card';

export function CommandConsole() {
    const [input, setInput] = useState('');
    const [logs, setLogs] = useState([
        { ts: '14:02:10', type: 'info', msg: 'System initialized. Ready for commands.' },
        { ts: '14:02:11', type: 'success', msg: 'Connected to AION-ZERO Mesh.' },
    ]);

    const handleSend = () => {
        if (!input.trim()) return;
        setLogs(prev => [...prev, { ts: new Date().toLocaleTimeString(), type: 'user', msg: `> ${input}` }]);
        setLogs(prev => [...prev, { ts: new Date().toLocaleTimeString(), type: 'info', msg: 'Parsing command via JARVIS-NLP...' }]);
        setInput('');
    };

    return (
        <Card className="flex flex-col h-full bg-slate-950/80 border-slate-800">
            <div className="flex items-center justify-between p-3 border-b border-slate-800 bg-slate-900/50">
                <div className="flex items-center gap-2 text-slate-400 text-sm font-mono">
                    <Terminal className="w-4 h-4" />
                    <span>COMMAND CONSOLE</span>
                </div>
                <div className="flex gap-1.5">
                    <span className="w-2.5 h-2.5 rounded-full bg-rose-500/20 border border-rose-500/50"></span>
                    <span className="w-2.5 h-2.5 rounded-full bg-amber-500/20 border border-amber-500/50"></span>
                    <span className="w-2.5 h-2.5 rounded-full bg-emerald-500/20 border border-emerald-500/50"></span>
                </div>
            </div>

            <div className="flex-1 p-4 font-mono text-sm space-y-2 overflow-y-auto min-h-[160px] max-h-[300px]">
                {logs.map((L, i) => (
                    <div key={i} className={`flex gap-3 ${L.type === 'user' ? 'text-sky-300 font-bold' : 'text-slate-300'}`}>
                        <span className="text-slate-600 select-none">[{L.ts}]</span>
                        <span>{L.msg}</span>
                    </div>
                ))}
            </div>

            <div className="p-3 border-t border-slate-800 bg-slate-900/30 flex gap-2">
                <div className="relative flex-1">
                    <Zap className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-sky-500 animate-pulse" />
                    <input
                        type="text"
                        value={input}
                        onChange={e => setInput(e.target.value)}
                        onKeyDown={e => e.key === 'Enter' && handleSend()}
                        placeholder="Type a command (e.g. 'Deploy OKASINA', 'Fix Bug in Server')..."
                        className="w-full bg-slate-950 border border-slate-700 rounded-lg pl-10 pr-4 py-2 text-slate-200 focus:outline-none focus:border-sky-500 transition-colors placeholder:text-slate-600"
                    />
                </div>
                <button
                    onClick={handleSend}
                    className="px-4 py-2 bg-sky-600 hover:bg-sky-500 text-white rounded-lg font-medium transition-colors flex items-center gap-2">
                    <Send className="w-4 h-4" />
                    RUN
                </button>
            </div>
        </Card>
    );
}
