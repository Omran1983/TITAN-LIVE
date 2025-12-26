import { useState } from "react";
import { apiPost } from "../lib/api";
import {
  Brain, MessageSquare, Terminal, Database,
  Workflow, Activity, RefreshCw, ExternalLink,
  Power, Shield
} from "lucide-react";

type ToolAction = {
  id: string;
  label: string;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  icon: any;
  type: 'link' | 'api';
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  payload?: any;
};

type Tool = {
  id: string;
  category: string;
  name: string;
  description: string;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  icon: any;
  status: "active" | "standby" | "off";
  version?: string;
  actions?: ToolAction[];
};

const TOOLS: Tool[] = [
  // Intelligence
  {
    id: "titan_brain",
    category: "Intelligence",
    name: "Titan Brain",
    description: "Cognitive core & Decision Engine",
    icon: Brain,
    status: "active", version: "v2.0",
    actions: [
      { id: "restart", label: "Restart Core", icon: RefreshCw, type: 'api', payload: {} }
    ]
  },
  {
    id: "ollama",
    category: "Intelligence",
    name: "Ollama",
    description: "Local LLM Inference",
    icon: MessageSquare,
    status: "active", version: "0.1.28",
    actions: [
      { id: "pull", label: "Pull Llama3", icon: Activity, type: 'api', payload: { model: 'llama3' } },
      { id: "restart", label: "Restart Service", icon: Power, type: 'api', payload: {} }
    ]
  },

  // Automation
  {
    id: "n8n",
    category: "Automation",
    name: "n8n",
    description: "Workflow Automation Engine",
    icon: Workflow,
    status: "active", version: "1.x",
    actions: [
      { id: "open", label: "Open Dashboard", icon: ExternalLink, type: 'link', payload: "http://localhost:5678" },
      { id: "restart", label: "Restart Process", icon: RefreshCw, type: 'api', payload: {} }
    ]
  },

  // Data
  {
    id: "supabase",
    category: "Data",
    name: "Supabase (PG)",
    description: "Primary Database & Vector Store",
    icon: Database,
    status: "active", version: "15.1",
    actions: [
      { id: "open", label: "Studio", icon: ExternalLink, type: 'link', payload: "http://localhost:54323" }
    ]
  },

  // Interface
  {
    id: "citadel",
    category: "Interface",
    name: "Glass Citadel",
    description: "Command Center UI",
    icon: Shield,
    status: "active", version: "1.0"
  },

  // Dev
  {
    id: "python",
    category: "DevOps",
    name: "Python 3.12",
    description: "Runtime Environment",
    icon: Terminal,
    status: "active", version: "3.12.3"
  }
];

export const ToolsPage = () => {
  const categories = ["Intelligence", "Automation", "Data", "Interface", "DevOps"];
  const [loading, setLoading] = useState<string | null>(null);

  const handleAction = async (toolId: string, action: ToolAction) => {
    if (action.type === 'link') {
      window.open(action.payload, '_blank');
      return;
    }

    setLoading(`${toolId}-${action.id}`);
    try {
      await apiPost("/api/tools/action", { tool: toolId, action: action.id, payload: action.payload });
      alert(`Action '${action.label}' initiated.`);
    } catch (e: any) {
      if (e.name === 'ApiError' && e.status === 403) {
        // Governance Denial
        alert(`⛔ Governance Blocked: ${e.message}`);
      } else {
        alert("Action failed: " + e.message);
      }
    } finally {
      setLoading(null);
    }
  };

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <header className="mb-8">
        <h1 className="text-3xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-blue-500 to-purple-600">
          System Toolbelt
        </h1>
        <p className="text-gray-500">Manage the active components of the Titan architecture.</p>
      </header>

      <div className="space-y-10">
        {categories.map(cat => (
          <div key={cat}>
            <h3 className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-4 border-b border-gray-100 pb-2">
              {cat} Stack
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {TOOLS.filter(t => t.category === cat).map((tool) => (
                <div key={tool.id} className="group bg-white rounded-2xl p-5 shadow-sm border border-gray-100 hover:shadow-md transition-all">
                  <div className="flex justify-between items-start mb-4">
                    <div className="p-3 bg-gray-50 rounded-xl group-hover:bg-blue-50 transition-colors">
                      <tool.icon className="w-6 h-6 text-gray-700 group-hover:text-blue-600" />
                    </div>
                    <div className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${tool.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                      {tool.status}
                    </div>
                  </div>

                  <div className="mb-4">
                    <h4 className="text-lg font-bold text-gray-900">{tool.name}</h4>
                    <p className="text-sm text-gray-500">{tool.description}</p>
                  </div>

                  <div className="flex flex-wrap gap-2 pt-4 border-t border-gray-50">
                    {tool.actions?.map(action => (
                      <button
                        key={action.id}
                        onClick={() => handleAction(tool.id, action)}
                        disabled={!!loading}
                        className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-gray-600 bg-gray-50 rounded-lg hover:bg-gray-100 hover:text-gray-900 transition-colors disabled:opacity-50"
                      >
                        {loading === `${tool.id}-${action.id}` ? (
                          <RefreshCw className="w-3 h-3 animate-spin" />
                        ) : (
                          <action.icon className="w-3 h-3" />
                        )}
                        {action.label}
                      </button>
                    ))}
                    {!tool.actions && <span className="text-xs text-gray-300 italic">No actions available</span>}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
