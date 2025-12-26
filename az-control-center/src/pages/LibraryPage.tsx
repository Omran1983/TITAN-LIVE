import React, { useEffect, useState } from 'react';
import { apiGet } from '../lib/api';
import { Search, Filter, Cpu, Database, Share2, Code, Download, X, Copy } from "lucide-react";

type WorkflowItem = {
    id: string;
    name: string;
    filename: string;
    nodes: string[] | string;
    is_gold: boolean;
};

type LibraryResp = { ok: boolean; items: WorkflowItem[] };

export const LibraryPage: React.FC = () => {
    const [items, setItems] = useState<WorkflowItem[]>([]);
    const [search, setSearch] = useState('');
    const [loading, setLoading] = useState(false);
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const [inspecting, setInspecting] = useState<any | null>(null);
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const [detailLoading, setDetailLoading] = useState(false);

    const [filter, setFilter] = useState('all');

    const fetchItems = async (q: string = '', cat: string = 'all') => {
        setLoading(true);
        try {
            // Using concatenation to avoid template string backtick issues
            const url = '/api/library?limit=100&q=' + encodeURIComponent(q) + '&cat=' + cat;
            const res = await apiGet<LibraryResp>(url);
            if (res.ok) setItems(res.items);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    const inspect = async (id: string, name: string) => {
        setDetailLoading(true);
        setInspecting({ name, loading: true });
        try {
            // Using concatenation
            const url = '/api/library/' + id;
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            const res = await apiGet<{ ok: boolean, workflow: any }>(url);
            if (res.ok) {
                setInspecting({ name, data: res.workflow });
            }
        } catch (e) {
            console.error(e);
        } finally {
            setDetailLoading(false);
        }
    };

    const closeInspector = () => setInspecting(null);

    const copyToClipboard = () => {
        if (inspecting?.data) {
            navigator.clipboard.writeText(JSON.stringify(inspecting.data, null, 2));
            alert("Copied JSON to clipboard!");
        }
    };

    useEffect(() => {
        fetchItems(search, filter);
    }, []);

    useEffect(() => {
        fetchItems(search, filter);
    }, [filter]);

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        fetchItems(search, filter);
    };

    return (
        <div className="p-8 max-w-7xl mx-auto relative">
            {/* Inspector Modal */}
            {inspecting && (
                <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={closeInspector}>
                    <div className="bg-white rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] flex flex-col overflow-hidden animate-in fade-in zoom-in duration-200" onClick={e => e.stopPropagation()}>
                        <div className="p-4 border-b flex justify-between items-center bg-gray-50">
                            <div className="flex items-center gap-3">
                                <div className="p-2 bg-blue-100 rounded-lg text-blue-600">
                                    <Code size={20} />
                                </div>
                                <div>
                                    <h2 className="font-bold text-lg text-gray-800">{inspecting.name || 'Workflow'}</h2>
                                    <div className="text-xs text-gray-500">n8n Workflow Definition</div>
                                </div>
                            </div>
                            <div className="flex gap-2">
                                <button onClick={copyToClipboard} className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 font-medium transition-colors shadow-sm">
                                    <Copy size={16} /> Copy JSON
                                </button>
                                <button onClick={closeInspector} className="p-2 hover:bg-gray-200 rounded-lg text-gray-500 transition-colors" aria-label="Close Inspector">
                                    <X size={20} />
                                </button>
                            </div>
                        </div>
                        <div className="flex-1 overflow-auto p-0 bg-[#1e1e1e]">
                            {inspecting.loading ? (
                                <div className="flex flex-col items-center justify-center h-full text-white/50 gap-4">
                                    <div className="w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
                                    <div className="text-sm">Fetching neural schematic...</div>
                                </div>
                            ) : (
                                <pre className="text-xs text-green-400 font-mono p-6">
                                    {JSON.stringify(inspecting.data, null, 2)}
                                </pre>
                            )}
                        </div>
                    </div>
                </div>
            )}

            <header className="mb-8 flex flex-col md:flex-row md:items-end justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-blue-600 to-purple-600 mb-2">
                        Automation Library
                    </h1>
                    <p className="text-gray-500 max-w-xl">
                        Browse top-tier agents, RAG pipelines, and operational workflows.
                        One-click copy to n8n.
                    </p>
                </div>

                <div className="flex gap-2">
                    <div className="relative">
                        <select
                            aria-label="Filter Category"
                            className="pl-10 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm appearance-none cursor-pointer hover:border-blue-300 transition-colors shadow-sm"
                            value={filter}
                            onChange={(e) => setFilter(e.target.value)}
                        >
                            <option value="all">All Categories</option>
                            <option value="gold">🏆 Gold Standard</option>
                            <option value="ai">🧠 AI / LLM</option>
                            <option value="crm">🤝 CRM / Sales</option>
                            <option value="social">📣 Social Media</option>
                            <option value="dev">🛠️ DevOps</option>
                        </select>
                        <Filter className="absolute left-3 top-2.5 text-gray-400 pointer-events-none" size={16} />
                    </div>

                    <form onSubmit={handleSearch} className="relative">
                        <input
                            type="text"
                            className="pl-10 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm w-64 shadow-sm"
                            placeholder="Find a workflow..."
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                        <Search className="absolute left-3 top-2.5 text-gray-400 pointer-events-none" size={16} />
                    </form>
                </div>
            </header>

            {loading ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 animate-pulse">
                    {[1, 2, 3, 4, 5, 6].map(i => (
                        <div key={i} className="h-40 bg-gray-100 rounded-2xl"></div>
                    ))}
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {items.map(item => {
                        // Parse nodes if string
                        let uniqueNodes: string[] = [];
                        try {
                            if (Array.isArray(item.nodes)) uniqueNodes = item.nodes;
                            // eslint-disable-next-line @typescript-eslint/no-explicit-any
                            else if (typeof item.nodes === 'string') uniqueNodes = JSON.parse(item.nodes as any);
                        } catch { }

                        const isAI = uniqueNodes.some(n => n.toLowerCase().includes('openai') || n.toLowerCase().includes('langchain') || n.toLowerCase().includes('vector'));
                        const isDb = uniqueNodes.some(n => n.toLowerCase().includes('postgres') || n.toLowerCase().includes('mysql'));

                        return (
                            <div key={item.id} className="group bg-white rounded-2xl p-5 shadow-sm border border-gray-100 hover:shadow-lg hover:border-blue-100 transition-all flex flex-col h-full">
                                <div className="flex justify-between items-start mb-3">
                                    <div className={`p-2.5 rounded-xl ${isAI ? 'bg-purple-100 text-purple-600' : isDb ? 'bg-cyan-100 text-cyan-700' : 'bg-blue-50 text-blue-600'}`}>
                                        {isAI ? <Cpu size={20} /> : isDb ? <Database size={20} /> : <Share2 size={20} />}
                                    </div>
                                    {item.is_gold && (
                                        <span className="text-[10px] font-bold bg-yellow-100 text-yellow-700 px-2 py-1 rounded-full uppercase tracking-wide">
                                            Gold
                                        </span>
                                    )}
                                </div>

                                <h3 className="font-bold text-gray-900 mb-1 line-clamp-1 group-hover:text-blue-600 transition-colors" title={item.name}>
                                    {item.name}
                                </h3>
                                <div className="text-xs text-gray-400 font-mono truncate mb-4 bg-gray-50 p-1 rounded px-2">
                                    {item.filename}
                                </div>

                                <div className="flex flex-wrap gap-1.5 mb-6 flex-1 content-start">
                                    {uniqueNodes.slice(0, 5).map((n, i) => (
                                        <span key={i} className="text-[10px] font-medium bg-gray-100 text-gray-600 px-2 py-0.5 rounded-md border border-gray-200">
                                            {n.replace('n8n-nodes-base.', '')}
                                        </span>
                                    ))}
                                    {uniqueNodes.length > 5 && (
                                        <span className="text-[10px] text-gray-400 py-0.5 px-1">+{uniqueNodes.length - 5}</span>
                                    )}
                                </div>

                                <button
                                    onClick={() => inspect(item.id, item.name)}
                                    className="w-full py-2.5 text-sm font-semibold text-gray-700 bg-gray-50 rounded-xl hover:bg-blue-600 hover:text-white transition-all flex items-center justify-center gap-2 group-hover:shadow-md"
                                >
                                    <Download size={16} /> Inspect & Get
                                </button>
                            </div>
                        )
                    })}
                </div>
            )}

            {!loading && items.length === 0 && (
                <div className="flex flex-col items-center justify-center py-24 text-gray-400">
                    <div className="p-4 bg-gray-50 rounded-full mb-4">
                        <Search size={32} />
                    </div>
                    <p>No workflows found for "{search}".</p>
                    <button onClick={() => { setSearch(''); setFilter('all') }} className="mt-2 text-blue-600 hover:underline text-sm">
                        Clear filters
                    </button>
                </div>
            )}
        </div>
    );
};
