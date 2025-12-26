import { useEffect, useState } from "react";
import { supabase } from "./supabaseClient";
import "./App.css";

// -----------------------------------------------------------------------------
// Navigation items
// -----------------------------------------------------------------------------
const NAV_ITEMS = [
  { id: "dashboard", label: "Dashboard" },
  { id: "employers", label: "Employers" },
  { id: "workers", label: "Workers" },
  { id: "agents", label: "Agents" },
  { id: "dormitories", label: "Dormitories" },
  { id: "requests", label: "Requests & Assignments" },
  { id: "finance", label: "Contracts & Finance" },
  { id: "settings", label: "Settings" },
];

// -----------------------------------------------------------------------------
// UI CONFIG – this is the master schema for field labels etc.
// Later we can persist this in Supabase. For now it lives in memory.
// -----------------------------------------------------------------------------
const DEFAULT_UI_CONFIG = {
  employers: {
    title: "Employers",
    description: "High-value accounts ReachX is serving or targeting.",
    fields: [
      {
        name: "employer_name",
        label: "Employer",
        type: "text",
        required: true,
        showInForm: true,
        showInList: true,
      },
      {
        name: "country",
        label: "Country",
        type: "text",
        required: false,
        showInForm: true,
        showInList: true,
      },
      {
        name: "sector",
        label: "Sector",
        type: "text",
        required: false,
        showInForm: true,
        showInList: true,
      },
      {
        name: "contact_person",
        label: "Contact Person",
        type: "text",
        required: false,
        showInForm: true,
        showInList: true,
      },
      {
        name: "contact_email",
        label: "Email",
        type: "email",
        required: false,
        showInForm: true,
        showInList: true,
      },
      {
        name: "contact_phone",
        label: "Phone",
        type: "text",
        required: false,
        showInForm: true,
        showInList: true,
      },
      {
        name: "status",
        label: "Status",
        type: "select",
        required: true,
        showInForm: true,
        showInList: true,
        options: [
          { value: "prospect", label: "Prospect" },
          { value: "active", label: "Active" },
          { value: "on-hold", label: "On hold" },
          { value: "closed", label: "Closed" },
        ],
      },
      {
        name: "vacancies_total",
        label: "Number of vacancies",
        type: "number",
        required: false,
        showInForm: true,
        showInList: true,
      },
      {
        name: "vacancies_filled",
        label: "Numbers filled",
        type: "number",
        required: false,
        showInForm: true,
        showInList: true,
      },
      {
        name: "monthly_revenue_estimate",
        label: "Monthly revenue estimate (MUR)",
        type: "number",
        required: false,
        showInForm: true,
        showInList: true,
      },
      {
        name: "unpaid_amount",
        label: "Unpaid amount (MUR)",
        type: "number",
        required: false,
        showInForm: true,
        showInList: true,
      },
    ],
  },
  workers: {
    title: "Workers",
    description: "Worker fields are still wired directly. Settings wiring next.",
    fields: [],
  },
  agents: {
    title: "Agents",
    description: "Agent fields are still wired directly. Settings wiring next.",
    fields: [],
  },
  dormitories: {
    title: "Dormitories",
    description:
      "Dormitory fields are still wired directly. Settings wiring next.",
    fields: [],
  },
};

// -----------------------------------------------------------------------------
// Small helpers
// -----------------------------------------------------------------------------
function Pill({ type = "info", children, style }) {
  let cls = "pill ";
  if (type === "info") cls += "pill-info";
  else if (type === "danger") cls += "pill-danger";
  else if (type === "warning") cls += "pill-warning";
  else if (type === "success") cls += "pill-success";
  return (
    <div className={cls} style={style}>
      {children}
    </div>
  );
}

function GenericTable({ rows }) {
  if (!rows || rows.length === 0) {
    return (
      <div className="table-wrapper">
        <table className="data-table">
          <tbody>
            <tr>
              <td className="empty-row">No data.</td>
            </tr>
          </tbody>
        </table>
      </div>
    );
  }

  const headers = Object.keys(rows[0]);

  return (
    <div className="table-wrapper">
      <table className="data-table">
        <thead>
          <tr>
            {headers.map((h) => (
              <th key={h}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, idx) => (
            <tr key={idx}>
              {headers.map((h) => (
                <td key={h}>{String(r[h] ?? "—")}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// Re-usable list hook (read-only)
function useSupabaseList(table, { select = "*", limit = 100 } = {}) {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      setError("");
      try {
        const { data, error } = await supabase
          .from(table)
          .select(select)
          .limit(limit);
        if (error) throw error;
        if (!cancelled) setRows(data || []);
      } catch (e) {
        if (!cancelled) setError(e.message || String(e));
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    load();
    return () => {
      cancelled = true;
    };
  }, [table, select, limit]);

  return { rows, loading, error };
}

// Single row helper
function useSupabaseSingle(table, { select = "*", single = true } = {}) {
  const [data, setData] = useState(single ? null : []);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      setError("");
      try {
        const query = supabase.from(table).select(select);
        const { data, error } = single ? await query.single() : await query;
        if (error) throw error;
        if (!cancelled) setData(data || (single ? null : []));
      } catch (e) {
        if (!cancelled) setError(e.message || String(e));
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    load();
    return () => {
      cancelled = true;
    };
  }, [table, select, single]);

  return { data, loading, error };
}

// -----------------------------------------------------------------------------
// Dashboard (Board + Automation)
// -----------------------------------------------------------------------------
function AutomationStrip() {
  const { rows: commands, loading: cmdsLoading, error: cmdsError } =
    useSupabaseList("az_commands", {
      select: "id, command, status, created_at",
      limit: 5,
    });

  const { rows: jobs, loading: jobsLoading, error: jobsError } =
    useSupabaseList("jarvis_jobs", {
      select: "id, job_type, status, created_at",
      limit: 5,
    });

  return (
    <div className="panel mt-lg">
      <h3 className="panel-title-sm">Jarvis Automation · Recent activity</h3>
      <p className="panel-subtitle-sm">
        This is where your “Board” actually moves: command queue + jobs running
        in the background.
      </p>

      {(cmdsLoading || jobsLoading) && <Pill>Loading automation logs…</Pill>}
      {(cmdsError || jobsError) && (
        <Pill type="danger">
          Error loading logs: {cmdsError || jobsError}
        </Pill>
      )}

      <div className="grid grid-2 mt-sm">
        <div>
          <div className="automation-title">Recent Commands (az_commands)</div>
          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Command</th>
                  <th>Status</th>
                  <th>Created</th>
                </tr>
              </thead>
              <tbody>
                {(!commands || commands.length === 0) && !cmdsLoading && (
                  <tr>
                    <td colSpan={4} className="empty-row">
                      No commands yet. When Jarvis or the UI queues work, it
                      shows here.
                    </td>
                  </tr>
                )}
                {commands.map((c) => (
                  <tr key={c.id}>
                    <td>{c.id}</td>
                    <td>{c.command}</td>
                    <td>{c.status}</td>
                    <td>{c.created_at}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div>
          <div className="automation-title">Recent Jobs (jarvis_jobs)</div>
          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Type</th>
                  <th>Status</th>
                  <th>Created</th>
                </tr>
              </thead>
              <tbody>
                {(!jobs || jobs.length === 0) && !jobsLoading && (
                  <tr>
                    <td colSpan={4} className="empty-row">
                      No jobs yet. When AutoHeal / Backup / Scrapers run, they
                      appear here.
                    </td>
                  </tr>
                )}
                {jobs.map((j) => (
                  <tr key={j.id}>
                    <td>{j.id}</td>
                    <td>{j.job_type || "—"}</td>
                    <td>{j.status}</td>
                    <td>{j.created_at}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}

function DashboardView() {
  const { data: kpis, loading, error } = useSupabaseSingle(
    "reachx_dashboard_kpis",
    { single: true }
  );

  const safe = kpis || {
    total_employers: 0,
    total_workers: 0,
    active_requests: 0,
    dorm_capacity: 0,
    dorm_occupied: 0,
  };

  return (
    <div className="panel">
      <h2 className="panel-title">ReachX · Command Console</h2>
      <p className="panel-subtitle">
        Jarvis Board · Status overview · You = CEO. Board = execution layer.
      </p>

      {loading && <Pill>Loading KPIs…</Pill>}
      {error && <Pill type="danger">Error: {error}</Pill>}

      <div className="grid grid-4">
        <div className="stat-card">
          <div className="stat-label">Employers</div>
          <div className="stat-value">{safe.total_employers}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Workers</div>
          <div className="stat-value">{safe.total_workers}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Active Requests</div>
          <div className="stat-value">{safe.active_requests}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Dorm Occupancy</div>
          <div className="stat-value">
            {safe.dorm_occupied}/{safe.dorm_capacity}
          </div>
        </div>
      </div>

      <div className="panel mt-lg">
        <h3 className="panel-title-sm">Virtual Board of Directors</h3>
        <p className="panel-subtitle-sm">
          Each “director” maps to real flows: tables, commands, and jobs.
        </p>
        <div className="grid grid-3">
          <div className="role-card">
            <div className="role-title">Director · ReachX Ops</div>
            <div className="role-owner">Owner: Omran</div>
            <ul className="role-list">
              <li>Employers, Workers, Agents flows</li>
              <li>Requests ↔ Assignments pipeline</li>
              <li>Dorm capacity & occupancy sanity</li>
            </ul>
          </div>
          <div className="role-card">
            <div className="role-title">Director · Finance & Contracts</div>
            <div className="role-owner">Owner: Jarvis-FIN</div>
            <ul className="role-list">
              <li>Contracts, invoices, unpaid alerts</li>
              <li>Monthly MUR snapshot exports</li>
              <li>Job hooks in jarvis_jobs</li>
            </ul>
          </div>
          <div className="role-card">
            <div className="role-title">Director · Data & Backups</div>
            <div className="role-owner">Owner: Jarvis-Autoheal</div>
            <ul className="role-list">
              <li>Supabase snapshot job (backup.snapshot)</li>
              <li>Schema / RLS sanity checks</li>
              <li>Healthcheck heartbeats</li>
            </ul>
          </div>
        </div>
      </div>

      <AutomationStrip />
    </div>
  );
}

// -----------------------------------------------------------------------------
// Employers – uses UI config for labels, with form as collapsible panel
// -----------------------------------------------------------------------------
function EmployersView({ uiConfig }) {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [showForm, setShowForm] = useState(false);

  const labelMap = {};
  (uiConfig?.fields || []).forEach((f) => {
    labelMap[f.name] = f.label;
  });
  const label = (name, fallback) => labelMap[name] || fallback;

  const [form, setForm] = useState({
    employer_name: "",
    country: "",
    sector: "",
    contact_person: "",
    contact_email: "",
    contact_phone: "",
    status: "prospect",
    vacancies_total: "",
    vacancies_filled: "",
    monthly_revenue_estimate: "",
    unpaid_amount: "",
  });

  const loadEmployers = async () => {
    setLoading(true);
    setError("");
    try {
      const { data, error } = await supabase
        .from("reachx_employers")
        .select(
          "id, employer_name, country, sector, contact_person, contact_email, contact_phone, status, vacancies_total, vacancies_filled, monthly_revenue_estimate, unpaid_amount"
        )
        .order("employer_name", { ascending: true });
      if (error) throw error;
      setRows(data || []);
    } catch (e) {
      setError(e.message || String(e));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadEmployers();
  }, []);

  const handleChange = (field, value) => {
    setForm((f) => ({ ...f, [field]: value }));
  };

  const resetForm = () => {
    setEditingId(null);
    setForm({
      employer_name: "",
      country: "",
      sector: "",
      contact_person: "",
      contact_email: "",
      contact_phone: "",
      status: "prospect",
      vacancies_total: "",
      vacancies_filled: "",
      monthly_revenue_estimate: "",
      unpaid_amount: "",
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError("");

    const payload = {
      ...form,
      vacancies_total: form.vacancies_total
        ? Number(form.vacancies_total)
        : 0,
      vacancies_filled: form.vacancies_filled
        ? Number(form.vacancies_filled)
        : 0,
      monthly_revenue_estimate: form.monthly_revenue_estimate
        ? Number(form.monthly_revenue_estimate)
        : 0,
      unpaid_amount: form.unpaid_amount ? Number(form.unpaid_amount) : 0,
    };

    try {
      if (editingId) {
        const { error } = await supabase
          .from("reachx_employers")
          .update(payload)
          .eq("id", editingId);
        if (error) throw error;
      } else {
        const { error } = await supabase
          .from("reachx_employers")
          .insert([payload]);
        if (error) throw error;
      }
      await loadEmployers();
      resetForm();
      setShowForm(false);
    } catch (e) {
      // This is where the RLS error shows up if policies block inserts
      alert("Error adding employer: " + (e.message || String(e)));
      setError(e.message || String(e));
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = (row) => {
    setEditingId(row.id);
    setShowForm(true);
    setForm({
      employer_name: row.employer_name || "",
      country: row.country || "",
      sector: row.sector || "",
      contact_person: row.contact_person || "",
      contact_email: row.contact_email || "",
      contact_phone: row.contact_phone || "",
      status: row.status || "prospect",
      vacancies_total: row.vacancies_total ?? "",
      vacancies_filled: row.vacancies_filled ?? "",
      monthly_revenue_estimate: row.monthly_revenue_estimate ?? "",
      unpaid_amount: row.unpaid_amount ?? "",
    });
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Delete this employer?")) return;
    setSaving(true);
    setError("");
    try {
      const { error } = await supabase
        .from("reachx_employers")
        .delete()
        .eq("id", id);
      if (error) throw error;
      await loadEmployers();
    } catch (e) {
      setError(e.message || String(e));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="panel">
      <div className="panel-header-row">
        <div>
          <h2 className="panel-title">Employers</h2>
          <p className="panel-subtitle">
            {uiConfig?.description ||
              "High-value accounts ReachX is serving or targeting."}
          </p>
          <div className="pill pill-soft">
            {rows.length} employers currently in the system.
          </div>
        </div>
        <div>
          <button
            type="button"
            className="btn-primary"
            onClick={() => setShowForm((v) => !v)}
          >
            {showForm
              ? editingId
                ? "Close editor"
                : "Hide add form"
              : "Add employer"}
          </button>
        </div>
      </div>

      {showForm && (
        <div className="panel mt-md">
          <h3 className="panel-title-sm">
            {editingId ? "Edit employer" : "Add employer"}
          </h3>
          <form className="form grid grid-2" onSubmit={handleSubmit}>
            <div>
              <div className="form-row">
                <label>
                  {label("employer_name", "Employer")} *
                </label>
                <input
                  value={form.employer_name}
                  onChange={(e) =>
                    handleChange("employer_name", e.target.value)
                  }
                  required
                />
              </div>
              <div className="form-row">
                <label>{label("country", "Country")}</label>
                <input
                  value={form.country}
                  onChange={(e) => handleChange("country", e.target.value)}
                />
              </div>
              <div className="form-row">
                <label>{label("sector", "Sector")}</label>
                <input
                  value={form.sector}
                  onChange={(e) => handleChange("sector", e.target.value)}
                />
              </div>
              <div className="form-row">
                <label>{label("contact_person", "Contact Person")}</label>
                <input
                  value={form.contact_person}
                  onChange={(e) =>
                    handleChange("contact_person", e.target.value)
                  }
                />
              </div>
              <div className="form-row">
                <label>{label("contact_email", "Email")}</label>
                <input
                  type="email"
                  value={form.contact_email}
                  onChange={(e) =>
                    handleChange("contact_email", e.target.value)
                  }
                />
              </div>
              <div className="form-row">
                <label>{label("contact_phone", "Phone")}</label>
                <input
                  value={form.contact_phone}
                  onChange={(e) =>
                    handleChange("contact_phone", e.target.value)
                  }
                />
              </div>
            </div>

            <div>
              <div className="form-row">
                <label>{label("status", "Status")}</label>
                <select
                  value={form.status}
                  onChange={(e) => handleChange("status", e.target.value)}
                >
                  {(uiConfig?.fields || []).find(
                    (f) => f.name === "status"
                  )?.options?.map((opt) => (
                    <option key={opt.value} value={opt.value}>
                      {opt.label}
                    </option>
                  )) || (
                    <>
                      <option value="prospect">Prospect</option>
                      <option value="active">Active</option>
                      <option value="on-hold">On hold</option>
                      <option value="closed">Closed</option>
                    </>
                  )}
                </select>
              </div>
              <div className="form-row">
                <label>{label("vacancies_total", "Number of vacancies")}</label>
                <input
                  type="number"
                  value={form.vacancies_total}
                  onChange={(e) =>
                    handleChange("vacancies_total", e.target.value)
                  }
                />
              </div>
              <div className="form-row">
                <label>{label("vacancies_filled", "Numbers filled")}</label>
                <input
                  type="number"
                  value={form.vacancies_filled}
                  onChange={(e) =>
                    handleChange("vacancies_filled", e.target.value)
                  }
                />
              </div>
              <div className="form-row">
                <label>
                  {label(
                    "monthly_revenue_estimate",
                    "Monthly revenue estimate (MUR)"
                  )}
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={form.monthly_revenue_estimate}
                  onChange={(e) =>
                    handleChange("monthly_revenue_estimate", e.target.value)
                  }
                />
              </div>
              <div className="form-row">
                <label>
                  {label("unpaid_amount", "Unpaid amount (MUR)")}
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={form.unpaid_amount}
                  onChange={(e) =>
                    handleChange("unpaid_amount", e.target.value)
                  }
                />
              </div>
            </div>

            <div className="form-actions span-2">
              <button type="submit" disabled={saving}>
                {saving
                  ? "Saving..."
                  : editingId
                  ? "Update employer"
                  : "Add employer"}
              </button>
              {editingId && (
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={resetForm}
                >
                  Cancel edit
                </button>
              )}
            </div>
          </form>
        </div>
      )}

      {loading && <Pill>Loading employers…</Pill>}
      {error && (
        <Pill type="danger" style={{ marginTop: "0.75rem" }}>
          Error: {error}
        </Pill>
      )}

      <div className="panel mt-lg">
        <h3 className="panel-title-sm">Employer list</h3>
        <div className="table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th>{label("employer_name", "Employer")}</th>
                <th>{label("country", "Country")}</th>
                <th>{label("sector", "Sector")}</th>
                <th>{label("contact_person", "Contact")}</th>
                <th>{label("contact_email", "Email")}</th>
                <th>{label("contact_phone", "Phone")}</th>
                <th>{label("status", "Status")}</th>
                <th>{label("vacancies_total", "Vacancies")}</th>
                <th>{label("vacancies_filled", "Filled")}</th>
                <th>{label("unpaid_amount", "Unpaid (MUR)")}</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.length === 0 && !loading && (
                <tr>
                  <td colSpan={11} className="empty-row">
                    No employers yet.
                  </td>
                </tr>
              )}
              {rows.map((e) => (
                <tr key={e.id}>
                  <td>{e.employer_name}</td>
                  <td>{e.country}</td>
                  <td>{e.sector}</td>
                  <td>{e.contact_person}</td>
                  <td>{e.contact_email}</td>
                  <td>{e.contact_phone}</td>
                  <td>{e.status}</td>
                  <td>{e.vacancies_total}</td>
                  <td>{e.vacancies_filled}</td>
                  <td>{e.unpaid_amount}</td>
                  <td>
                    <div className="row-actions">
                      <button
                        type="button"
                        onClick={() => handleEdit(e)}
                      >
                        Edit
                      </button>
                      <button
                        type="button"
                        className="btn-danger"
                        onClick={() => handleDelete(e.id)}
                      >
                        Del
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

// -----------------------------------------------------------------------------
// Workers (read-only for now)
// -----------------------------------------------------------------------------
function WorkersView() {
  const { rows, loading, error } = useSupabaseList("reachx_workers", {
    select:
      "id, full_name, nationality, skill_category, status, employer_id, agent_id, visa_status, visa_expiry, salary_expected, salary_paid, benefits, agreement_id",
    limit: 200,
  });

  return (
    <div className="panel">
      <h2 className="panel-title">Workers</h2>
      <p className="panel-subtitle">
        Blue-collar talent currently tracked in ReachX.
      </p>

      {loading && <Pill>Loading workers…</Pill>}
      {error && <Pill type="danger">Error: {error}</Pill>}

      <div className="table-wrapper">
        <table className="data-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Nationality</th>
              <th>Skill Category</th>
              <th>Status</th>
              <th>Employer ID</th>
              <th>Agent ID</th>
              <th>Visa Status</th>
              <th>Visa Expiry</th>
              <th>Salary Expected</th>
              <th>Salary Paid</th>
              <th>Benefits</th>
              <th>Agreement ID</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 && !loading && (
              <tr>
                <td colSpan={12} className="empty-row">
                  No workers yet.
                </td>
              </tr>
            )}
            {rows.map((w) => (
              <tr key={w.id}>
                <td>{w.full_name}</td>
                <td>{w.nationality}</td>
                <td>{w.skill_category}</td>
                <td>{w.status}</td>
                <td>{w.employer_id || "—"}</td>
                <td>{w.agent_id || "—"}</td>
                <td>{w.visa_status || "—"}</td>
                <td>{w.visa_expiry || "—"}</td>
                <td>{w.salary_expected ?? "—"}</td>
                <td>{w.salary_paid ?? "—"}</td>
                <td>{w.benefits || "—"}</td>
                <td>{w.agreement_id || "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <Pill type="warning" style={{ marginTop: "1rem" }}>
        Add/Edit/Delete for workers will follow the same pattern as Employers
        once this pass is stable.
      </Pill>
    </div>
  );
}

// -----------------------------------------------------------------------------
// Agents (read-only table)
// -----------------------------------------------------------------------------
function AgentsView() {
  const { rows, loading, error } = useSupabaseList("reachx_agents", {
    select:
      "id, name, country, phone, email, staff_introduced, commission_paid, notes",
    limit: 200,
  });

  return (
    <div className="panel">
      <h2 className="panel-title">Agents</h2>
      <p className="panel-subtitle">
        Human agents and partners that introduce staff and manage employers.
        (AI agents will surface here via jarvis_runs later.)
      </p>

      {loading && <Pill>Loading agents…</Pill>}
      {error && <Pill type="danger">Error: {error}</Pill>}

      <GenericTable rows={rows} />

      <Pill type="warning" style={{ marginTop: "1rem" }}>
        Next step: add Jarvis bot runs here (AutoHeal / Scraper / Comms) so you
        see both human and AI agents in one place.
      </Pill>
    </div>
  );
}

// -----------------------------------------------------------------------------
// Dormitories (basic CRUD)
// -----------------------------------------------------------------------------
function DormitoriesView() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [editingId, setEditingId] = useState(null);

  const [form, setForm] = useState({
    name: "",
    location: "",
    contact_person: "",
    contact_email: "",
    contact_phone: "",
    rooms: "",
    capacity: "",
    occupied: "",
    rent_demanded: "",
    rent_paid: "",
    amount_pending: "",
    contract_length_months: "",
    contract_expiry: "",
  });

  const loadDorms = async () => {
    setLoading(true);
    setError("");
    try {
      const { data, error } = await supabase
        .from("reachx_dormitories")
        .select(
          "id, name, location, contact_person, contact_email, contact_phone, rooms, capacity, occupied, rent_demanded, rent_paid, amount_pending, contract_length_months, contract_expiry"
        )
        .order("name", { ascending: true });
      if (error) throw error;
      setRows(data || []);
    } catch (e) {
      setError(e.message || String(e));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDorms();
  }, []);

  const handleChange = (field, value) => {
    setForm((f) => ({ ...f, [field]: value }));
  };

  const resetForm = () => {
    setEditingId(null);
    setForm({
      name: "",
      location: "",
      contact_person: "",
      contact_email: "",
      contact_phone: "",
      rooms: "",
      capacity: "",
      occupied: "",
      rent_demanded: "",
      rent_paid: "",
      amount_pending: "",
      contract_length_months: "",
      contract_expiry: "",
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError("");

    const payload = {
      name: form.name,
      location: form.location,
      contact_person: form.contact_person,
      contact_email: form.contact_email,
      contact_phone: form.contact_phone,
      rooms: form.rooms ? Number(form.rooms) : null,
      capacity: form.capacity ? Number(form.capacity) : null,
      occupied: form.occupied ? Number(form.occupied) : 0,
      rent_demanded: form.rent_demanded ? Number(form.rent_demanded) : null,
      rent_paid: form.rent_paid ? Number(form.rent_paid) : null,
      amount_pending: form.amount_pending ? Number(form.amount_pending) : null,
      contract_length_months: form.contract_length_months
        ? Number(form.contract_length_months)
        : null,
      contract_expiry: form.contract_expiry || null,
    };

    try {
      if (editingId) {
        const { error } = await supabase
          .from("reachx_dormitories")
          .update(payload)
          .eq("id", editingId);
        if (error) throw error;
      } else {
        const { error } = await supabase
          .from("reachx_dormitories")
          .insert([payload]);
        if (error) throw error;
      }
      await loadDorms();
      resetForm();
    } catch (e) {
      setError(e.message || String(e));
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = (row) => {
    setEditingId(row.id);
    setForm({
      name: row.name || "",
      location: row.location || "",
      contact_person: row.contact_person || "",
      contact_email: row.contact_email || "",
      contact_phone: row.contact_phone || "",
      rooms: row.rooms ?? "",
      capacity: row.capacity ?? "",
      occupied: row.occupied ?? "",
      rent_demanded: row.rent_demanded ?? "",
      rent_paid: row.rent_paid ?? "",
      amount_pending: row.amount_pending ?? "",
      contract_length_months: row.contract_length_months ?? "",
      contract_expiry: row.contract_expiry
        ? row.contract_expiry.slice(0, 10)
        : "",
    });
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Delete this dormitory?")) return;
    setSaving(true);
    setError("");
    try {
      const { error } = await supabase
        .from("reachx_dormitories")
        .delete()
        .eq("id", id);
      if (error) throw error;
      await loadDorms();
    } catch (e) {
      setError(e.message || String(e));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="panel">
      <h2 className="panel-title">Dormitories</h2>
      <p className="panel-subtitle">
        Name, address, contact, rooms, rent, contract length, expiry.
      </p>

      {loading && <Pill>Loading dormitories…</Pill>}
      {error && <Pill type="danger">Error: {error}</Pill>}

      <div className="grid grid-2 mt-md">
        <div>
          <h3 className="panel-title-sm">
            {editingId ? "Edit dormitory" : "Add dormitory"}
          </h3>
          <form className="form" onSubmit={handleSubmit}>
            <div className="form-row">
              <label>Name</label>
              <input
                value={form.name}
                onChange={(e) => handleChange("name", e.target.value)}
                required
              />
            </div>
            <div className="form-row">
              <label>Address / Location</label>
              <input
                value={form.location}
                onChange={(e) => handleChange("location", e.target.value)}
              />
            </div>
            <div className="form-row">
              <label>Contact Person</label>
              <input
                value={form.contact_person}
                onChange={(e) =>
                  handleChange("contact_person", e.target.value)
                }
              />
            </div>
            <div className="form-row">
              <label>Contact Email</label>
              <input
                type="email"
                value={form.contact_email}
                onChange={(e) =>
                  handleChange("contact_email", e.target.value)
                }
              />
            </div>
            <div className="form-row">
              <label>Contact Phone</label>
              <input
                value={form.contact_phone}
                onChange={(e) =>
                  handleChange("contact_phone", e.target.value)
                }
              />
            </div>
            <div className="form-row">
              <label>No. of rooms</label>
              <input
                type="number"
                value={form.rooms}
                onChange={(e) => handleChange("rooms", e.target.value)}
              />
            </div>
            <div className="form-row">
              <label>Capacity (beds)</label>
              <input
                type="number"
                value={form.capacity}
                onChange={(e) => handleChange("capacity", e.target.value)}
              />
            </div>
            <div className="form-row">
              <label>Occupied</label>
              <input
                type="number"
                value={form.occupied}
                onChange={(e) => handleChange("occupied", e.target.value)}
              />
            </div>
            <div className="form-row">
              <label>Rent demanded (MUR)</label>
              <input
                type="number"
                step="0.01"
                value={form.rent_demanded}
                onChange={(e) =>
                  handleChange("rent_demanded", e.target.value)
                }
              />
            </div>
            <div className="form-row">
              <label>Rent paid (MUR)</label>
              <input
                type="number"
                step="0.01"
                value={form.rent_paid}
                onChange={(e) => handleChange("rent_paid", e.target.value)}
              />
            </div>
            <div className="form-row">
              <label>Amount pending (MUR)</label>
              <input
                type="number"
                step="0.01"
                value={form.amount_pending}
                onChange={(e) =>
                  handleChange("amount_pending", e.target.value)
                }
              />
            </div>
            <div className="form-row">
              <label>Contract length (months)</label>
              <input
                type="number"
                value={form.contract_length_months}
                onChange={(e) =>
                  handleChange("contract_length_months", e.target.value)
                }
              />
            </div>
            <div className="form-row">
              <label>Contract expiry date</label>
              <input
                type="date"
                value={form.contract_expiry}
                onChange={(e) =>
                  handleChange("contract_expiry", e.target.value)
                }
              />
            </div>
            <div className="form-actions">
              <button type="submit" disabled={saving}>
                {saving
                  ? "Saving..."
                  : editingId
                  ? "Update dormitory"
                  : "Add dormitory"}
              </button>
              {editingId && (
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={resetForm}
                >
                  Cancel edit
                </button>
              )}
            </div>
          </form>
        </div>

        <div>
          <h3 className="panel-title-sm">Dormitory list</h3>
          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Location</th>
                  <th>Rooms</th>
                  <th>Capacity</th>
                  <th>Occupied</th>
                  <th>Rent Demanded</th>
                  <th>Rent Paid</th>
                  <th>Pending</th>
                  <th>Contract Expiry</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {rows.length === 0 && !loading && (
                  <tr>
                    <td colSpan={10} className="empty-row">
                      No dormitories yet.
                    </td>
                  </tr>
                )}
                {rows.map((d) => (
                  <tr key={d.id}>
                    <td>{d.name}</td>
                    <td>{d.location}</td>
                    <td>{d.rooms}</td>
                    <td>{d.capacity}</td>
                    <td>{d.occupied}</td>
                    <td>{d.rent_demanded}</td>
                    <td>{d.rent_paid}</td>
                    <td>{d.amount_pending}</td>
                    <td>{d.contract_expiry?.slice(0, 10) || "—"}</td>
                    <td>
                      <div className="row-actions">
                        <button
                          type="button"
                          onClick={() => handleEdit(d)}
                        >
                          Edit
                        </button>
                        <button
                          type="button"
                          className="btn-danger"
                          onClick={() => handleDelete(d.id)}
                        >
                          Del
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <Pill type="info" style={{ marginTop: "1rem" }}>
            Complaints, repairs & maintenance are logged in
            reachx_dorm_issues. We can add a sub-panel for that next.
          </Pill>
        </div>
      </div>
    </div>
  );
}

// -----------------------------------------------------------------------------
// Requests & Assignments
// -----------------------------------------------------------------------------
function RequestsAssignmentsView() {
  const {
    rows: requests,
    loading: reqLoading,
    error: reqError,
  } = useSupabaseList("reachx_requests", {
    select: "id, employer_id, requested_workers, status, created_at",
    limit: 200,
  });

  const {
    rows: assignments,
    loading: asgLoading,
    error: asgError,
  } = useSupabaseList("reachx_assignments", {
    select: "id, employer_id, worker_id, status, created_at",
    limit: 200,
  });

  return (
    <div className="panel">
      <h2 className="panel-title">Requests & Assignments</h2>
      <p className="panel-subtitle">
        Flow: Employer makes request → ReachX matches workers → assignments are
        created.
      </p>

      {(reqLoading || asgLoading) && <Pill>Loading pipeline…</Pill>}
      {(reqError || asgError) && (
        <Pill type="danger">Error: {reqError || asgError}</Pill>
      )}

      <div className="grid grid-2 mt-sm">
        <div>
          <div className="automation-title">Requests</div>
          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Employer ID</th>
                  <th>Requested workers</th>
                  <th>Status</th>
                  <th>Created</th>
                </tr>
              </thead>
              <tbody>
                {requests.length === 0 && !reqLoading && (
                  <tr>
                    <td colSpan={5} className="empty-row">
                      No requests yet.
                    </td>
                  </tr>
                )}
                {requests.map((r) => (
                  <tr key={r.id}>
                    <td>{r.id}</td>
                    <td>{r.employer_id}</td>
                    <td>{r.requested_workers}</td>
                    <td>{r.status}</td>
                    <td>{r.created_at}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div>
          <div className="automation-title">Assignments</div>
          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Employer ID</th>
                  <th>Worker ID</th>
                  <th>Status</th>
                  <th>Created</th>
                </tr>
              </thead>
              <tbody>
                {assignments.length === 0 && !asgLoading && (
                  <tr>
                    <td colSpan={5} className="empty-row">
                      No assignments yet.
                    </td>
                  </tr>
                )}
                {assignments.map((a) => (
                  <tr key={a.id}>
                    <td>{a.id}</td>
                    <td>{a.employer_id}</td>
                    <td>{a.worker_id}</td>
                    <td>{a.status}</td>
                    <td>{a.created_at}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <Pill type="info" style={{ marginTop: "1rem" }}>
        Next step: allow creating requests directly from an employer card, and
        auto-suggest workers for assignment.
      </Pill>
    </div>
  );
}

// -----------------------------------------------------------------------------
// Contracts & Finance
// -----------------------------------------------------------------------------
function FinanceView() {
  const { rows, loading, error } = useSupabaseList("reachx_employers", {
    select:
      "id, employer_name, country, vacancies_total, vacancies_filled, monthly_revenue_estimate, unpaid_amount, billing_currency",
    limit: 200,
  });

  const totalMonthly = rows.reduce(
    (sum, r) => sum + (r.monthly_revenue_estimate || 0),
    0
  );
  const totalUnpaid = rows.reduce(
    (sum, r) => sum + (r.unpaid_amount || 0),
    0
  );

  return (
    <div className="panel">
      <h2 className="panel-title">Contracts & Finance</h2>
      <p className="panel-subtitle">
        Simple view: potential monthly value per employer and unpaid amounts. We
        can later swap this to a full invoices table if you want.
      </p>

      {loading && <Pill>Loading finance…</Pill>}
      {error && <Pill type="danger">Error: {error}</Pill>}

      <div className="grid grid-2 mt-sm">
        <div className="stat-card">
          <div className="stat-label">Total monthly estimate</div>
          <div className="stat-value">
            MUR {totalMonthly.toLocaleString("en-MU")}
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Total unpaid</div>
          <div className="stat-value">
            MUR {totalUnpaid.toLocaleString("en-MU")}
          </div>
        </div>
      </div>

      <div className="table-wrapper mt-md">
        <table className="data-table">
          <thead>
            <tr>
              <th>Employer</th>
              <th>Country</th>
              <th>Vacancies</th>
              <th>Filled</th>
              <th>Monthly estimate (MUR)</th>
              <th>Unpaid (MUR)</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 && !loading && (
              <tr>
                <td colSpan={6} className="empty-row">
                  No employers yet.
                </td>
              </tr>
            )}
            {rows.map((e) => (
              <tr key={e.id}>
                <td>{e.employer_name}</td>
                <td>{e.country}</td>
                <td>{e.vacancies_total}</td>
                <td>{e.vacancies_filled}</td>
                <td>{e.monthly_revenue_estimate}</td>
                <td>{e.unpaid_amount}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <Pill type="info" style={{ marginTop: "1rem" }}>
        When you’re ready, we can add reachx_contracts + reachx_invoices and
        show actual contract + invoice lines here.
      </Pill>
    </div>
  );
}

// -----------------------------------------------------------------------------
// Settings – master control for field labels / visibility
// -----------------------------------------------------------------------------
function SettingsView({ uiConfig, setUiConfig }) {
  const [section, setSection] = useState("employers");

  const sectionCfg = uiConfig[section] || { fields: [] };

  const updateField = (fieldName, patch) => {
    const updatedSection = {
      ...sectionCfg,
      fields: sectionCfg.fields.map((f) =>
        f.name === fieldName ? { ...f, ...patch } : f
      ),
    };
    setUiConfig({
      ...uiConfig,
      [section]: updatedSection,
    });
  };

  return (
    <div className="panel">
      <h2 className="panel-title">Settings</h2>
      <p className="panel-subtitle">
        Control labels and visibility for each tab. This is how we make ReachX
        multi-industry and multi-country without touching code.
      </p>

      <div
        style={{
          display: "flex",
          gap: "0.5rem",
          margin: "1rem 0",
          flexWrap: "wrap",
        }}
      >
        {["employers", "workers", "agents", "dormitories"].map((id) => (
          <button
            key={id}
            type="button"
            onClick={() => setSection(id)}
            style={{
              padding: "0.4rem 0.9rem",
              borderRadius: "999px",
              border: "1px solid rgba(255,255,255,0.06)",
              background:
                section === id ? "rgba(59,130,246,0.2)" : "rgba(15,23,42,0.9)",
              color: "#e5e7eb",
              fontSize: "0.85rem",
              cursor: "pointer",
            }}
          >
            {id.charAt(0).toUpperCase() + id.slice(1)}
          </button>
        ))}
      </div>

      {sectionCfg.fields.length === 0 ? (
        <Pill type="info">
          This section still uses hardcoded fields. We’ve wired Employers first;
          once you’re happy with the model we’ll mirror it to the other tabs.
        </Pill>
      ) : (
        <>
          <Pill type="info" style={{ marginBottom: "0.75rem" }}>
            Tip: change labels here and then flip back to the Employers tab to
            see the UI adapt instantly.
          </Pill>
          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>DB field</th>
                  <th>Label shown in UI</th>
                  <th>Type</th>
                  <th>Show in form</th>
                  <th>Show in list</th>
                  <th>Required</th>
                </tr>
              </thead>
              <tbody>
                {sectionCfg.fields.map((f) => (
                  <tr key={f.name}>
                    <td>{f.name}</td>
                    <td>
                      <input
                        value={f.label}
                        onChange={(e) =>
                          updateField(f.name, { label: e.target.value })
                        }
                      />
                    </td>
                    <td>{f.type}</td>
                    <td style={{ textAlign: "center" }}>
                      <input
                        type="checkbox"
                        checked={f.showInForm}
                        onChange={(e) =>
                          updateField(f.name, {
                            showInForm: e.target.checked,
                          })
                        }
                      />
                    </td>
                    <td style={{ textAlign: "center" }}>
                      <input
                        type="checkbox"
                        checked={f.showInList}
                        onChange={(e) =>
                          updateField(f.name, {
                            showInList: e.target.checked,
                          })
                        }
                      />
                    </td>
                    <td style={{ textAlign: "center" }}>
                      <input
                        type="checkbox"
                        checked={f.required}
                        onChange={(e) =>
                          updateField(f.name, {
                            required: e.target.checked,
                          })
                        }
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      <Pill type="warning" style={{ marginTop: "0.75rem" }}>
        Right now settings live in this browser only. Next step: store them in a
        <code> reachx_ui_config </code> table in Supabase so Jarvis and all UIs
        share the same schema.
      </Pill>
    </div>
  );
}

// -----------------------------------------------------------------------------
// Main shell
// -----------------------------------------------------------------------------
export default function App() {
  const [active, setActive] = useState("dashboard");
  const [uiConfig, setUiConfig] = useState(DEFAULT_UI_CONFIG);

  let content;
  switch (active) {
    case "dashboard":
      content = <DashboardView />;
      break;
    case "employers":
      content = <EmployersView uiConfig={uiConfig.employers} />;
      break;
    case "workers":
      content = <WorkersView />;
      break;
    case "agents":
      content = <AgentsView />;
      break;
    case "dormitories":
      content = <DormitoriesView />;
      break;
    case "requests":
      content = <RequestsAssignmentsView />;
      break;
    case "finance":
      content = <FinanceView />;
      break;
    case "settings":
      content = (
        <SettingsView uiConfig={uiConfig} setUiConfig={setUiConfig} />
      );
      break;
    default:
      content = <DashboardView />;
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="brand-title">ReachX · Board</div>
          <div className="brand-sub">Jarvis Control Surface</div>
        </div>
        <nav className="nav">
          {NAV_ITEMS.map((item) => (
            <button
              key={item.id}
              className={
                "nav-item" + (active === item.id ? " nav-item-active" : "")
              }
              onClick={() => setActive(item.id)}
            >
              {item.label}
            </button>
          ))}
        </nav>
        <div className="sidebar-footer">
          <div className="footer-label">You:</div>
          <div className="footer-value">Omran · CEO · Hands-off mode</div>
        </div>
      </aside>
      <main className="main-area">
        {content}
        <footer className="main-footer">
          Engine: Jarvis HQ API + CommandWorker · Data: Supabase · Project:
          ReachX-AI
        </footer>
      </main>
    </div>
  );
}
