# TITAN SYSTEM CONTRACT & DEFINITIONS

> **Status**: APPROVED
> **Version**: 1.0.0
> **Date**: 2025-12-20

## 1. Product Boundaries (The "Block" Contract)

Effective immediately, TITAN products must adhere to the **Block Architecture**.

### Definition of a "Block"
A Block is a self-contained, sellable unit of automation.
*   **Must coexist**: Cannot break other blocks.
*   **Must contain**:
    *   `rules.json` (The Logic/Policy)
    *   `validate_*.py` (The Enforcement Engine)
    *   `run_*.ps1` (The Execution Interface)
    *   `tests/` (Proof of Correctness)
*   **Input**: Defined CSV/JSON schema.
*   **Output**: JSON Report + Optional PDF.

### Block List (Current)
*   `TITAN-HR`: PRB-2026 Compliance & Audit.
*   `TITAN-AI`: Readiness & Digital Asset Tracking (Planned).
*   `TITAN-ENV`: Carbon & Waste Reporting (Planned).

---

## 2. Autonomy Levels (Governance)

Agents and Blocks must operate within assigned **Autonomy Levels**.

| Level | Name | Description | Permissions |
| :--- | :--- | :--- | :--- |
| **L0** | **Passive Monitor** | Read-only. Logs data. | `READ`, `LOG`, `NOTIFY` |
| **L1** | **Advisor** | Recommendations. Human executes. | `GENERATE_DRAFT`, `SUGGEST` |
| **L2** | **Human-in-the-Loop** | Agent executes after implicit/explicit approval. | `EXECUTE_WITH_CONFIRMATION` |
| **L3** | **Bounded Autonomous** | Agent executes within strict, pre-approved limits. | `EXECUTE_WITHIN_LIMITS` (e.g., < $50 spend) |
| **L4** | **High Autonomy** | Agent sets strategy & executes. (Rare). | `FULL_EXECUTION` |

**TITAN-HR Current Level**: **L0/L1** (Validation & Reporting Only).
**Constraint**: NO database writes to HR Systems without L3 Upgrade.

---

## 3. Evidence-First Principle

*   **Rule**: "If it is not in the JSON logic, it does not exist."
*   **Enforcement**: "If there is no evidence (data check), the status is `FAIL` or `INSUFFICIENT_DATA`."
*   **Audit**: All Block runs must produce a timestamped, persistent Artifact (JSON/PDF).

## 4. Repository Hygiene

*   **Configs**: stored in `config/` or block root.
*   **Secrets**: `.env` ONLY. Never committed.
*   **Data**: `data/` or `inputs/`. gitignored.
*   **Logs**: `logs/`. gitignored.

---
**Signed**: TITAN System Administrator
