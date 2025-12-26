# TITAN STRATEGIC BLOCK MAP

> **Vision**: 12–15 sellable blocks — clean, composable, and plug-and-play with TITAN OS.
> **Status**: ACTIVE

## The Rule (Non-Negotiable)

Every block must:
*   Declare **rules** (JSON)
*   Run via **standard runner** (`run_block_name.ps1`)
*   Write to **Audit/Evidence Ledger**
*   Respect **Autonomy Levels (L0–L4)**
*   Output **proof** (PDF/CSV/logs)

---

## Tier 1 — Sell Now (Regulation & Fear-Driven)
*Fast revenue. Mandatory demand. Low competition.*

1.  **HR Compliance Block (PRB-2026)** ✅ `blocks/hr_compliance`
    *   *Core*: Min wage, increments, employer obligations.
    *   *Evidence*: Salary logs, training records.
2.  **Payroll Validation Overlay**
    *   *Core*: Checks payroll output vs rules (checksums, variance).
    *   *Evidence*: Variance report vs previous month.
3.  **Labour Law Obligations Block**
    *   *Core*: Contracts, working hours, leave balances.
    *   *Evidence*: Contract validity checks, leave audit.
4.  **Environmental Compliance Block**
    *   *Core*: Plastics usage, permits, ESG reporting.
    *   *Evidence*: Consumption logs, permit status.
5.  **Health & Safety Compliance Block**
    *   *Core*: Policy distribution, incident logging, training.
    *   *Evidence*: Training signatures, incident register.

## Tier 2 — Sell Next (Cost, Risk, Productivity)
*CFO/COO buyers. Strong ROI narrative.*

6.  **AI Readiness & Digitalisation Block** (Vision-2050 aligned)
    *   *Core*: Tool adoption, digital skill baseline.
    *   *Evidence*: Usage logs, certification tracking.
7.  **Productivity & Output Block**
    *   *Core*: Wage vs Output justification.
    *   *Evidence*: Activity logs vs payroll cost.
8.  **Vendor & Contract Compliance Block**
    *   *Core*: SLA monitoring, renewal tracking, penalty enforcement.
    *   *Evidence*: Vendor performance report.
9.  **Data Protection & Privacy Block**
    *   *Core*: Record retention, access controls, breach readiness.
    *   *Evidence*: Access audit logs, policy check.

## Tier 3 — Operational Upside (After Trust)
*Sold once TITAN is inside the org.*

10. **Uptime & SLA Monitoring Block**
    *   *Core*: Website/API availability (Heartbeat).
    *   *Evidence*: Uptime logs, latency graphs.
11. **Price & Margin Monitor Block** (OKASINA / Commerce)
    *   *Core*: Competitor pricing, margin integrity.
    *   *Evidence*: Price scrape comparison.
12. **Procurement Spend Control Block**
    *   *Core*: PO approval gates, budget variance.
    *   *Evidence*: Spend vs Budget report.
13. **Incident & Root-Cause Block**
    *   *Core*: Ops failure tracking, resolution time.
    *   *Evidence*: Post-mortem logs.

## Tier 4 — Strategic / Premium (Optional)
*High-margin, fewer buyers.*

14. **Audit-Ready Board Reporting Block**
    *   *Core*: Automated board deck generation (Finance/Ops/Risk).
    *   *Evidence*: Generated PDF Deck.
15. **Jurisdiction Expansion Pack**
    *   *Core*: PRB-2027 / New Country Rules.
    *   *Evidence*: Multi-jurisdictional compliance report.

---

## Technical Integration Standard (SB-I)

**Path Structure**:
```
/blocks/<block_name>/
  rules.json          # The definition
  validate_rules.py   # The engine
  run_block.ps1       # The interface
  evidence/           # The input data
  reports/            # The output proof
```

**Shared Services (OS Layer)**:
*   TITAN Scheduler
*   Reflex Engine (Self-Healing)
*   Citadel UI (Visualization) – *Read-Only from Reports*

---
**Maintained By**: Director of Automation & AI Systems (Atlas)
