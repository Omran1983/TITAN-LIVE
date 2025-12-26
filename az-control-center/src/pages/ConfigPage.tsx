import { useEffect, useState } from "react";
import { apiGet } from "../lib/api";

type ConfigResp = { ok: boolean; config: Record<string, string> };

export const ConfigPage = () => {
  const [cfg, setCfg] = useState<Record<string, string>>({});
  const [err, setErr] = useState<string>("");

  useEffect(() => {
    apiGet<ConfigResp>("/api/config")
      .then((d) => setCfg(d.config || {}))
      .catch((e) => setErr(e?.message ?? "Failed"));
  }, []);

  return (
    <div className="p-4">
      <h2>Config</h2>
      <div className="opacity-80 mt-2">
        Values are sanitized; sensitive keys are masked.
      </div>
      {err && <div className="text-red mt-3">{err}</div>}

      <div className="table-container">
        <table className="w-full-table">
          <thead>
            <tr>
              <th align="left">Key</th>
              <th align="left">Value</th>
            </tr>
          </thead>
          <tbody>
            {Object.entries(cfg).map(([k, v]) => (
              <tr key={k} className="border-top">
                <td className="cell-pad"><code>{k}</code></td>
                <td className="cell-pad"><code>{v}</code></td>
              </tr>
            ))}
            {Object.keys(cfg).length === 0 && !err && (
              <tr><td colSpan={2} className="p-3">No config received.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
