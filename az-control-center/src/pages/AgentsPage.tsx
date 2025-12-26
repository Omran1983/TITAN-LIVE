import { useEffect, useState } from "react";
import { apiGet } from "../lib/api";

type Agent = {
  pid: number;
  name: string;
  cmdline: string[];
  status: string;
  cpu_percent: number;
  memory_rss: number;
  started_at: number;
  username?: string;
};

type AgentsResp = { ok: boolean; agents: Agent[] };

function fmtBytes(n: number) {
  const units = ["B", "KB", "MB", "GB", "TB"];
  let v = n;
  let i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return `${v.toFixed(i === 0 ? 0 : 1)} ${units[i]}`;
}

export const AgentsPage = () => {
  const [items, setItems] = useState<Agent[]>([]);
  const [err, setErr] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(true);

  const load = () => {
    setLoading(true);
    setErr("");
    apiGet<AgentsResp>("/api/agents")
      .then((d) => setItems(d.agents || []))
      .catch((e) => setErr(e?.message ?? "Failed"))
      .finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  return (
    <div className="p-4">
      <h2>Agents</h2>
      <button onClick={load} className="mt-2">Refresh</button>

      {loading && <div className="mt-3">Loading…</div>}
      {err && <div className="text-red mt-3">{err}</div>}

      {!loading && !err && (
        <div className="table-container">
          <table className="w-full-table">
            <thead>
              <tr>
                <th align="left">PID</th>
                <th align="left">Name</th>
                <th align="left">Status</th>
                <th align="left">CPU%</th>
                <th align="left">Memory</th>
                <th align="left">Started</th>
                <th align="left">Cmdline</th>
              </tr>
            </thead>
            <tbody>
              {items.map((a) => (
                <tr key={a.pid} className="border-top">
                  <td>{a.pid}</td>
                  <td>{a.name}</td>
                  <td>{a.status}</td>
                  <td>{(a.cpu_percent ?? 0).toFixed(1)}</td>
                  <td>{fmtBytes(a.memory_rss ?? 0)}</td>
                  <td>{a.started_at ? new Date(a.started_at * 1000).toLocaleString() : "—"}</td>
                  <td className="max-w-cmd">
                    <code className="code-nowrap">{(a.cmdline || []).join(" ").slice(0, 200)}</code>
                  </td>
                </tr>
              ))}
              {items.length === 0 && (
                <tr><td colSpan={7} className="p-3">No matching agent processes found.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
