# 🛡️ AION-ZERO: GOVERNANCE & COMPLIANCE LAYER
**Standard Operating Procedure (SOP-001)**

---

## 1. IDENTITY & ACCESS MANAGEMENT (IAM)
AION-ZERO uses a **Role-Based Access Control (RBAC)** system rooted in Supabase RLS (Row Level Security).

### Roles
1.  **SysAdmin (Root)**: Can modify `az_mesh_routes`, manage API keys, and trigger `Ignition`.
2.  **Operator**: Can chat, request analysis, and trigger "Safe" tools (`ReadFile`, `CheckStatus`).
3.  **Auditor**: Read-only access to `az_chat_history` and `az_audit_logs`.
4.  **Agent (Service Role)**: The AI agents themselves (`Jarvis-Brain`). Restricted by Circuit Breakers.

### Implementation Plan
*   **Table**: `az_permissions` (user_id, permission_scope).
*   **Enforcement**: The `Jarvis-MeshProxy` checks the `source_agent` token before routing traffic.

---

## 2. THE KILL-SWITCH (PANIC PROTOCOL)
**Trigger**: `scripts/Panic-Stop.ps1`
**Effect**:
1.  Terminates all Python/PowerShell worker processes immediately.
2.  Renames `.env` to `.env.lock` (preventing auto-restart).
3.  Sends a "System Down" signal to the Watchdog log.
**Restoration**: Requires manual SysAdmin intervention (Physical Access).

---

## 3. AUDIT & LOGGING POLICY
**"If it isn't logged, it didn't happen."**

### Data Classification
*   **L1 (Public/Safe)**: UI Layouts, System Status. -> *Local Logs*.
*   **L2 (Internal)**: Code Snippets, Build Logs. -> *Supabase `az_chat_history`*.
*   **L3 (Sensitive)**: PII, Credentials, Financial Data. -> *Redacted locally before Cloud Burst*.

### The "Black Box"
Every decision made by the AI (`think()`) is assigned a `decision_id` and stored in `az_decision_trace`.
*   **Input**: User Prompt + Context.
*   **Reasoning**: The "Thought" field from the JSON.
*   **Action**: The Tool execution.
*   **Outcome**: Success/Failure status.

---

## 4. MULTI-TENANCY ISOLATION
To serve multiple clients (SaaS Mode):
1.  **Row-Level Isolation**: Every table (`az_memories`, `az_logs`) gets a `tenant_id` column.
2.  **RLS Policies**: `CREATE POLICY tenant_isolation ON az_memories USING (tenant_id = current_tenant_id());`
3.  **Mesh Segregation**: Agent Routes are scoped. `tenant_a_agent` cannot route to `tenant_b_agent`.

---

## 5. HUMAN-IN-THE-LOOP (HITL)
**Autonomy Levels**:
*   **Level 0 (Advisor)**: AI suggests code. Human copies/pastes. (Current State).
*   **Level 1 (Co-Pilot)**: AI suggests actions. Human clicks "Approve" in Citadel UI.
*   **Level 2 (Autopilot)**: AI acts. Human is notified. (Low Risk tasks).
*   **Level 3 (Autonomous)**: AI acts. Logs for audit. (High Trust).

**Default Setting**: Level 1.
