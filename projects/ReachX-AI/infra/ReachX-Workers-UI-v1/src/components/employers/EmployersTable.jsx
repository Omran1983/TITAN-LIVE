import React, { useState } from "react";

export function EmployersTable({
  employers,
  loading,
  onAdd,
  onEditSelected,
  onDeleteSelected,
}) {
  const [selectedIds, setSelectedIds] = useState([]);

  const toggleRow = (id) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  };

  const toggleAll = () => {
    if (!employers || employers.length === 0) return;
    if (selectedIds.length === employers.length) {
      setSelectedIds([]);
    } else {
      setSelectedIds(employers.map((e) => e.employer_id));
    }
  };

  const handleEditClick = () => {
    if (!selectedIds.length) {
      window.alert("Select at least one employer to edit.");
      return;
    }
    onEditSelected && onEditSelected(selectedIds);
  };

  const handleDeleteClick = () => {
    if (!selectedIds.length) {
      window.alert("Select at least one employer to delete.");
      return;
    }
    onDeleteSelected && onDeleteSelected(selectedIds);
  };

  return (
    <div>
      <div className="table-toolbar">
        <div className="toolbar-left">
          <strong>Employers</strong>{" "}
          <span style={{ fontSize: 12, opacity: 0.7 }}>
            ({employers?.length || 0} total)
          </span>
          {selectedIds.length > 0 && (
            <span style={{ fontSize: 12, marginLeft: 8 }}>
              · {selectedIds.length} selected
            </span>
          )}
        </div>
        <div className="toolbar-right">
          <button type="button" onClick={onAdd} disabled={loading}>
            + Add employer
          </button>
          <button
            type="button"
            onClick={handleEditClick}
            disabled={loading || selectedIds.length === 0}
            className="btn-secondary"
            style={{ marginLeft: 8 }}
          >
            Edit selected
          </button>
          <button
            type="button"
            onClick={handleDeleteClick}
            disabled={loading || selectedIds.length === 0}
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
            </tr>
          </thead>
          <tbody>
            {(!employers || employers.length === 0) && !loading && (
              <tr>
                <td colSpan={12} className="empty-row">
                  No employers yet.
                </td>
              </tr>
            )}
            {employers.map((e) => (
              <tr key={e.employer_id}>
                <td>
                  <input
                    type="checkbox"
                    checked={selectedIds.includes(e.employer_id)}
                    onChange={() => toggleRow(e.employer_id)}
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
  );
}
