import { useEffect, useState } from "react";
import { apiGet } from "../lib/api";
import {
  Activity,
  Heart,
  Zap,
  Clock,
  Target,
  TrendingUp,
  AlertTriangle
} from "lucide-react";

type HealthResp = Record<string, unknown> & { ok?: boolean };
type BeaconResp = { ok: boolean; beacon: unknown };

type Mission = {
  id: string;
  mission_name: string;
  start_ts: string;
  end_ts?: string;
  status: string;
  gained_val: number;
};

export const HealthPage = () => {
  const [status, setStatus] = useState<unknown>(null);
  const [beacon, setBeacon] = useState<unknown>(null);
  const [missions, setMissions] = useState<Mission[]>([]);
  const [err, setErr] = useState<string>("");

  useEffect(() => {
    Promise.all([
      apiGet<HealthResp>("/api/status"),
      apiGet<BeaconResp>("/api/health/beacon"),
      apiGet<Mission[]>("/api/missions"),
    ])
      .then(([s, b, m]) => {
        setStatus(s);
        setBeacon(b?.beacon ?? b);
        setMissions(m || []);
      })
      .catch((e) => setErr(e?.message ?? "Failed"));
  }, []);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-200 p-8 font-sans">
      <div className="max-w-7xl mx-auto space-y-8">

        {/* Header */}
        <div className="flex items-center gap-3 border-b border-white/10 pb-6">
          <div className="p-3 bg-emerald-500/10 rounded-2xl ring-1 ring-emerald-500/20">
            <Heart className="w-6 h-6 text-emerald-400" />
          </div>
          <div>
            <h2 className="text-2xl font-bold text-slate-100 tracking-tight">System Health</h2>
            <div className="text-sm text-slate-400">Real-time telemetry and mission status</div>
          </div>
        </div>

        {err && (
          <div className="flex items-center gap-3 bg-rose-500/10 border border-rose-500/20 text-rose-200 p-4 rounded-xl">
            <AlertTriangle className="w-5 h-5" />
            <span>Error loading telemetry: {err}</span>
          </div>
        )}

        {/* Metrics Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">

          {/* Metric Card 1 */}
          <div className="relative overflow-hidden rounded-2xl border border-white/5 bg-white/[0.02] p-6 hover:bg-white/[0.04] transition-colors group">
            <div className="absolute inset-0 bg-gradient-to-br from-blue-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
            <div className="relative flex flex-col items-center text-center">
              <div className="mb-4 p-3 rounded-full bg-blue-500/10 text-blue-400 ring-1 ring-blue-500/20">
                <Zap className="w-6 h-6" />
              </div>
              <div className="text-xs font-semibold uppercase tracking-wider text-slate-500">Operating Mode</div>
              <div className="mt-1 text-xl font-bold text-slate-100 capitalize">
                {(status as any)?.mode ?? 'Unknown'}
              </div>
            </div>
          </div>

          {/* Metric Card 2 */}
          <div className="relative overflow-hidden rounded-2xl border border-white/5 bg-white/[0.02] p-6 hover:bg-white/[0.04] transition-colors group">
            <div className="absolute inset-0 bg-gradient-to-br from-emerald-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
            <div className="relative flex flex-col items-center text-center">
              <div className="mb-4 p-3 rounded-full bg-emerald-500/10 text-emerald-400 ring-1 ring-emerald-500/20">
                <Activity className="w-6 h-6" />
              </div>
              <div className="text-xs font-semibold uppercase tracking-wider text-slate-500">Core Status</div>
              <div className="mt-1 text-xl font-bold text-emerald-400 capitalize">
                {(status as any)?.status ?? 'Offline'}
              </div>
            </div>
          </div>

          {/* Metric Card 3 */}
          <div className="relative overflow-hidden rounded-2xl border border-white/5 bg-white/[0.02] p-6 hover:bg-white/[0.04] transition-colors group">
            <div className="absolute inset-0 bg-gradient-to-br from-indigo-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
            <div className="relative flex flex-col items-center text-center">
              <div className="mb-4 p-3 rounded-full bg-indigo-500/10 text-indigo-400 ring-1 ring-indigo-500/20">
                <Target className="w-6 h-6" />
              </div>
              <div className="text-xs font-semibold uppercase tracking-wider text-slate-500">Missions Run</div>
              <div className="mt-1 text-xl font-bold text-slate-100">
                {(status as any)?.stats?.missions_run ?? 0}
              </div>
            </div>
          </div>

          {/* Metric Card 4 */}
          <div className="relative overflow-hidden rounded-2xl border border-white/5 bg-white/[0.02] p-6 hover:bg-white/[0.04] transition-colors group">
            <div className="absolute inset-0 bg-gradient-to-br from-amber-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
            <div className="relative flex flex-col items-center text-center">
              <div className="mb-4 p-3 rounded-full bg-amber-500/10 text-amber-400 ring-1 ring-amber-500/20">
                <Clock className="w-6 h-6" />
              </div>
              <div className="text-xs font-semibold uppercase tracking-wider text-slate-500">Uptime Checks</div>
              <div className="mt-1 text-xl font-bold text-slate-100">
                {(status as any)?.stats?.uptime_checks ?? 0}
              </div>
            </div>
          </div>
        </div>

        {/* Missions Table */}
        <div className="rounded-2xl border border-white/10 bg-white/[0.02] overflow-hidden">
          <div className="border-b border-white/10 px-6 py-4 flex items-center justify-between bg-white/[0.02]">
            <h3 className="font-semibold text-slate-200">Recent Missions</h3>
            <div className="text-xs text-slate-500">Last 50 executions</div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-white/5 text-slate-500">
                  <th className="px-6 py-3 font-medium">Mission Name</th>
                  <th className="px-6 py-3 font-medium">Status</th>
                  <th className="px-6 py-3 font-medium">Impact</th>
                  <th className="px-6 py-3 font-medium">Started</th>
                  <th className="px-6 py-3 font-medium text-right">Duration</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {missions.map((m) => {
                  const isSuccess = m.status === 'success';
                  const isFail = m.status === 'failed' || m.status === 'error';

                  const start = new Date(m.start_ts);
                  const end = m.end_ts ? new Date(m.end_ts) : null;
                  const duration = end
                    ? ((end.getTime() - start.getTime()) / 1000 / 60).toFixed(1) + 'm'
                    : <span className="text-amber-400 animate-pulse">Running</span>;

                  return (
                    <tr key={m.id} className="hover:bg-white/[0.02] transition-colors group">
                      <td className="px-6 py-4 font-medium text-slate-300 group-hover:text-slate-100 transition-colors">
                        {m.mission_name}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ring-1 ring-inset capitalize ${isSuccess ? 'bg-emerald-500/10 text-emerald-400 ring-emerald-500/20' :
                            isFail ? 'bg-rose-500/10 text-rose-400 ring-rose-500/20' :
                              'bg-blue-500/10 text-blue-400 ring-blue-500/20'
                          }`}>
                          <span className={`w-1.5 h-1.5 rounded-full ${isSuccess ? 'bg-emerald-400' : isFail ? 'bg-rose-400' : 'bg-blue-400'
                            }`} />
                          {m.status}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        {m.gained_val > 0 && <span className="text-emerald-400 font-mono font-medium flex items-center gap-1"><TrendingUp className="w-3 h-3" /> +{m.gained_val}</span>}
                        {m.gained_val === 0 && <span className="text-slate-600 font-mono">-</span>}
                      </td>
                      <td className="px-6 py-4 text-slate-500 font-mono text-xs">
                        {start.toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                      </td>
                      <td className="px-6 py-4 text-slate-500 font-mono text-xs text-right">
                        {duration}
                      </td>
                    </tr>
                  );
                })}
                {missions.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-slate-500 italic">
                      No missions recorded yet.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
