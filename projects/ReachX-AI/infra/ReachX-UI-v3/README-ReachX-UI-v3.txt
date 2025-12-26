ReachX UI v3 — Summary
======================

Look & Layout
-------------
- Dark, calm console layout
- Fixed sidebar with navigation:
  Dashboard, Staff, Employers, Agents, Candidates,
  Dormitories, Placements, Communication, Contracts, Roles
- Each entity page has:
  - Hero header (title + short description)
  - Card: "Add ..." form
  - Card: List (table) with filters

Features (per entity page)
--------------------------
- Add records via the top form
- Data stored in browser localStorage:
  STORAGE_KEY = "reachx_v3_entities"
- Search box:
  - Filters by name + field1 + field2
- Status filter:
  - "All" + 3 statuses (Active / Pending / Closed variants)
- Count badge showing number of visible rows
- Delete action per row
- "Reset demo data" button:
  - Clears storage
  - Reseeds sample dataset for all entities

Data flow
---------
1. On page load:
   - JS checks SEED_FLAG = "reachx_v3_seeded"
   - If not set, writes a sample dataset to localStorage
   - Loads current entity array (e.g. staff, employers, agents...)
   - Renders rows into the table

2. On submit:
   - Form values → row object
   - row.status defaults to "active" if missing
   - Row unshifted into entity array (newest first)
   - Entity array saved back into localStorage
   - Table re-rendered

3. On search / status change:
   - Filtered in-memory (no server calls)

4. On delete:
   - Row removed from entity array
   - Saved + re-rendered

Gaps / Next feature ideas
-------------------------
- Backend integration:
  - Replace localStorage with Supabase / API endpoints
  - Use IDs and foreign keys (candidate_id, employer_id, dorm_id)
- Cross-screen actions:
  - From Employers, jump to Placements filtered by employer
  - From Candidates, jump to Communication filtered by candidate
- Attachments:
  - Link to contract PDF, visa, passport, etc.
- Tasks & reminders:
  - Simple "next action" per candidate/employer with due dates
- Permissions:
  - Hook Roles into real RBAC in your backend

This UI is meant to be a clean, focused front-end skeleton you can plug into
real data without changing the structure of the pages.
