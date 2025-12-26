# ReachX – Definition of Done (MVP)

## 1. Core Pages (UI)

Required HTML files (under infra/ReachX-Workers-UI-v1):

- index.html          → Landing / navigation
- dashboard.html      → Global stats: workers, employers, dorms, open requests
- mployers.html      → Table of employers + status + active workers
- workers.html        → Table of workers (filters: employer, status, location)
- dormitories.html    → Table of dormitories (capacity, occupied, free beds)
- equests.html       → Employer requests form + list of requests
- invoices.html       → List of employer invoices (basic billing view)

Each page must include a root element:

- dashboard.html   → <div id="reachx-dashboard-root">
- mployers.html   → <div id="reachx-employers-root">
- workers.html     → <div id="reachx-workers-root">
- dormitories.html → <div id="reachx-dorms-root">
- equests.html    → <div id="reachx-requests-root">
- invoices.html    → <div id="reachx-invoices-root">

## 2. Supabase Schema (Tables/Views)

Tables (or equivalent):

- mployers:
  - id, 
ame, sector, location, status
- workers:
  - id, ull_name, skill, mployer_id, dormitory_id, status
- dormitories:
  - id, 
ame, location, capacity, occupied_beds
- mployer_requests:
  - id, mployer_id, ole, count, start_date, status
- ssignments:
  - id, worker_id, mployer_id, start_date, nd_date, daily_rate

View:

- mployer_invoices_view:
  - mployer_id, mployer_name, month, 	otal_workers, 	otal_amount

## 3. .env Configuration

Project root (F:\ReachX-AI\.env) must define:

- SUPABASE_URL
- SUPABASE_ANON_KEY
- REACHX_PUBLIC_BASE_URL (Cloudflare Pages or similar)

All must be non-empty.

## 4. Health Checks

To call ReachX "DONE (MVP)", all must be true:

1. All HTML files exist and contain their root IDs.
2. All core tables exist and have at least 1 row:
   - mployers, workers, dormitories
3. mployer_invoices_view exists and is queryable.
4. REACHX_PUBLIC_BASE_URL returns HTTP 200 and contains the text ReachX on index.html.

If any of the above fails, ReachX is **NOT DONE**.
