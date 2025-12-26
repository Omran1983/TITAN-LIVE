import React, { useEffect, useState } from "react";
import { supabase } from "../../supabaseClient";

export function EmployersSection() {
  const [employers, setEmployers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  const [editingId, setEditingId] = useState(null);
  const [selectedIds, setSelectedIds] = useState([]);

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

  // ---------- Load data ----------

  const loadEmployers = async () => {
    setLoading(true);
    setError(null);
    try {
      const { data, error } = await supabase
        .from("reachx_employers")
        .select(
          `
          id,
          employer_name,
          country,
          sector,
          contact_person,
          contact_email,
          contact_phone,
          status,
          vacancies_total,
          vacancies_filled,
          monthly_revenue_estimate,
          unpaid_amount
        `
        )
        .order("employer_name", { ascending: true });

      if (error) throw error;
      setEmployers(data || []);
    } catch (err) {
      console.error("Error loading employers:", err);
      setError(err.message || "Failed to load employers");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadEmployers();
  }, []);

  // ---------- Helpers ----------

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

  const handleFormChange = (field, value) => {
    setForm((prev) => ({ ...prev, [field]: value }));
  };

  const toggleRow = (id) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  };

  const toggleAll = () => {
    if (!employers.length) return;
    if (selectedIds.length === employers.length) {
      setSelectedIds([]);
    } else {
      setSelectedIds(employers.map((e) => e.id));
    }
  };

  // ---------- Create / Update ----------

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError(null);

    const payload = {
      employer_name: form.employer_name,
      country: form.country || null,
      sector: form.sector || null,
      contact_person: form.contact_person || null,
      contact_email: form.contact_email || null,
      contact_phone: form.contact_phone || null,
      status: form.status || "prospect",
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
      setSelectedIds([]);
    } catch (err) {
      console.error("Error saving employer:", err);
      window.alert(
        "Error saving employer: " + (err.message || String(err))
      );
      setError(err.message || "Error saving employer");
    } finally {
      setSaving(false);
    }
  };

  const handleEditRow = (row) => {
    setEditingId(row.id);
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

  const handleEditSelected = () => {
    if (!selectedIds.length) {
      window.alert("Select at least one employer to edit.");
      return;
    }
    const first = employers.find((e) => e.id === selectedIds[0]);
    if (!first) {
      window.alert("Could not find selected employer.");
      return;
    }
    handleEditRow(first);
  };

  // ---------- Delete ----------

  const handleDeleteSelected = async () => {
    if (!selectedIds.length) {
      window.alert("Select at least one employer to delete.");
      return;
    }

    if (
      !window.confirm(
        `Are you sure you want to delete ${selectedIds.length} employer(s)? This cannot be undone.`
      )
    ) {
      return;
    }

    setSaving(true);
    setError(null);

    try {
      const { error } = await supabase
        .from("reachx_employers")
        .delete()
        .in("id", selectedIds);

      if (error) throw error;

      await loadEmployers();
      setSelectedIds([]);
      resetForm();
    } catch (err) {
      console.error("Error deleting employers:", err);
      window.alert(
        "Error deleting employers: " + (err.message || String(err))
      );
      setError(err.message || "Error deleting employers");
    } finally {
      setSaving(false);
    }
  };

  // ---------- Render ----------

  return (
    <div className="panel">
      <h2 className="panel-title">Employers</h2>
      <p className="panel-subtitle">
        High-value accounts ReachX is serving or targeting.
      </p>

      <div style={{ marginBottom: 8 }}>
        {saving && (
          <span style={{ fontSize: 12, color: "#2563eb", marginRight: 12 }}>
            Saving changes…
          </span>
        )}
        {error && (
          <span style={{ fontSize: 12, color: "#b91c1c" }}>Error: {error}</span>
        )}
      </div>

      <div className="grid grid-2 mt-md">
        {/* LEFT: Form */}
        <div>
          <h3 className="panel-title-sm">
            {editingId ? "Edit employer" : "Add employer"}
          </h3>
          <form className="form" onSubmit={handleSubmit}>
            <div className="form-row">
              <label>Employer</label>
              <input
                value={form.employer_name}
                onChange={(e) =>
                  handleFormChange("employer_name", e.target.value)
                }
                required
              />
            </div>
            <div className="form-row">
              <label>Country</label>
              <input
                value={form.country}
                onChange={(e) =>
                  handleFormChange("country", e.target.value)
                }
              />
            </div>
            <div className="form-row">
              <label>Sector</label>
              <input
                value={form.sector}
                onChange={(e) => handleFormChange("sector", e.target.value)}
              />
            </div>
            <div className="form-row">
              <label>Contact Person</label>
              <input
                value={form.contact_person}
                onChange={(e) =>
                  handleFormChange("contact_person", e.target.value)
                }
              />
            </div>
            <div className="form-row">
              <label>Email</label>
              <input
                type="email"
                value={form.contact_email}
                onChange={(e) =>
                  handleFormChange("contact_email", e.target.value)
                }
              />
            </div>
            <div className="form-row">
              <label>Phone</label>
              <input
                value={form.contact_phone}
                onChange={(e) =>
                  handleFormChange("contact_phone", e.target.value)
                }
              />
            </div>
            <div className="form-row">
              <label>Status</label>
              <select
                value={form.status}
                onChange={(e) => handleFormChange("status", e.target.value)}
              >
                <option value="prospect">Prospect</option>
                <option value="active">Active</option>
                <option value="on-hold">On hold</option>
                <option value="closed">Closed</option>
              </select>
            </div>
            <div className="form-row">
              <label>Number of vacancies</label>
              <input
                type="number"
                value={form.vacancies_total}
                onChange={(e) =>
                  handleFormChange("vacancies_total", e.target.value)
                }
              />
            </div>
            <div className="form-row">
              <label>Numbers filled</label>
              <input
                type="number"
                value={form.vacancies_filled}
                onChange={(e) =>
                  handleFormChange("vacancies_filled", e.target.value)
                }
              />
            </div>
            <div className="form-row">
              <label>Monthly revenue estimate (MUR)</label>
              <input
                type="number"
                step="0.01"
                value={form.monthly_revenue_estimate}
                onChange={(e) =>
                  handleFormChange(
                    "monthly_revenue_estimate",
                    e.target.value
                  )
                }
              />
            </div>
            <div className="form-row">
              <label>Unpaid amount (MUR)</label>
              <input
                type="number"
                step="0.01"
                value={form.unpaid_amount}
                onChange={(e) =>
                  handleFormChange("unpaid_amount", e.target.value)
                }
              />
            </div>

            <div className="form-actions">
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

        {/* RIGHT: Table + bulk actions */}
        <div>
          <div className="table-toolbar">
            <div className="toolbar-left">
              <strong>Employers</strong>{" "}
              <span style={{ fontSize: 12, opacity: 0.7 }}>
                ({employers.length} total)
              </span>
              {selectedIds.length > 0 && (
                <span style={{ fontSize: 12, marginLeft: 8 }}>
                  · {selectedIds.length} selected
                </span>
              )}
            </div>
            <div className="toolbar-right">
              <button
                type="button"
                onClick={handleEditSelected}
                disabled={saving || !selectedIds.length}
                className="btn-secondary"
              >
                Edit selected
              </button>
              <button
                type="button"
                onClick={handleDeleteSelected}
                disabled={saving || !selectedIds.length}
                className="btn-danger"
                style={{ marginLeft: 8 }}
              >
                Delete selected
              </button>
            </div>
          </div>

          <div className="table-wrapper mt-sm">
            <table className="data-table">
              <thead>
                <tr>
                  <th>
                    <input
                      type="checkbox"
                      onChange={toggleAll}
                      checked={
                        employers.length > 0 &&
                        selectedIds.length === employers.length
                      }
                    />
                  </th>
                  <th>Employer</th>
                  <th>Country</th>
                  <th>Sector</th>
                  <th>Contact</th>
                  <th>Email</th>
                  <th>Phone</th>
                  <th>Status</th>
                  <th>Vacancies</th>
                  <th>Filled</th>
                  <th>Monthly (MUR)</th>
                  <th>Unpaid (MUR)</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {employers.length === 0 && !loading && (
                  <tr>
                    <td colSpan={13} className="empty-row">
                      No employers yet.
                    </td>
                  </tr>
                )}
                {employers.map((e) => (
                  <tr key={e.id}>
                    <td>
                      <input
                        type="checkbox"
                        checked={selectedIds.includes(e.id)}
                        onChange={() => toggleRow(e.id)}
                      />
                    </td>
                    <td>{e.employer_name}</td>
                    <td>{e.country}</td>
                    <td>{e.sector}</td>
                    <td>{e.contact_person}</td>
                    <td>{e.contact_email}</td>
                    <td>{e.contact_phone}</td>
                    <td>{e.status}</td>
                    <td>{e.vacancies_total}</td>
                    <td>{e.vacancies_filled}</td>
                    <td>{e.monthly_revenue_estimate}</td>
                    <td>{e.unpaid_amount}</td>
                    <td>
                      <div className="row-actions">
                        <button
                          type="button"
                          onClick={() => handleEditRow(e)}
                        >
                          Edit
                        </button>
                        <button
                          type="button"
                          className="btn-danger"
                          onClick={async () => {
                            setSelectedIds([e.id]);
                            await handleDeleteSelected();
                          }}
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

          {loading && (
            <div style={{ fontSize: 12, marginTop: 8, opacity: 0.7 }}>
              Loading employers…
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
