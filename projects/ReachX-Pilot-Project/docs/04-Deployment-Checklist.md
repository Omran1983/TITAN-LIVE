# ReachX Pilot â€“ Deployment Checklist (Internal)

Use this checklist each time you prepare and launch a new pilot.  
You can copy this into your own task management tool if you like.

---

## Before talking to the client

- [ ] Confirm which Supabase project will host their data.
- [ ] Confirm Cloudflare Pages project / URL to use for their dashboard.
- [ ] Ensure core scripts are working in your own test environment:
  - `ReachX-Heartbeat.ps1`
  - `ReachX-Autopilot.ps1`
  - `ReachX-Refresh-All.ps1`
  - `ReachX-Deploy-UI.ps1`
  - `ReachX-UI-Ping.ps1`
  - `ReachX-Status.ps1`
- [ ] Have the latest:
  - Pilot one-pager (`docs/01-ReachX-Pilot-OnePager.md`)
  - Data template guide (`docs/02-Data-Template-Guide.md`)
  - Flyer text (`marketing/flyer-A4.txt`)

---

## Before Day 1 (once client is interested)

- [ ] Share the data templates (CSV or Excel) with the client.
- [ ] Explain which columns are mandatory and which are optional.
- [ ] Agree on:
  - 1 point of contact.
  - A rough start date and target end date (14 days).
- [ ] Confirm how they will share the files (email, shared drive, etc.).

---

## Day 1â€“3: Setup

- [ ] Receive completed templates from the client.
- [ ] Inspect data for obvious issues (missing columns, wrong formats).
- [ ] Import data into Supabase tables:
  - `employers`
  - `workers`
  - `dormitories`
- [ ] Deploy or confirm the Cloudflare Pages dashboard URL.
- [ ] Manually run:
  - `ReachX-Heartbeat.ps1`
  - `ReachX-Refresh-All.ps1` (or `ReachX-Autopilot.ps1`)
- [ ] Check that:
  - Dashboard loads without error.
  - Counts for employers/workers/dormitories look reasonable.
- [ ] Send:
  - Live dashboard URL.
  - Short "how to use" note to the client.

---

## Day 4â€“10: Live usage

- [ ] Confirm scheduled tasks (Heartbeat / Autopilot / UI Ping) are active in Task Scheduler.
- [ ] Once or twice during this period:
  - Run `ReachX-Status.ps1`.
  - Confirm status=OK and counts are in a normal range.
- [ ] Ask the client:
  - Is data accurate?
  - Are there obvious missing fields?
  - Are they actually using it?

- [ ] Apply small adjustments where needed:
  - Adding columns to the UI.
  - Adjusting filters.
  - Minor layout changes (optional).

---

## Day 11â€“14: Review and decision

- [ ] Generate a short summary:
  - Uptime (any known outages?).
  - Final counts of workers/employers/dormitories.
  - Incidents (if any) and how they were fixed.
- [ ] Schedule a review call or meeting.
- [ ] During the review:
  - Ask what value they saw.
  - Ask what they would need to feel confident using it daily.
- [ ] Discuss:
  - Continuing on a paid plan,
  - Extending pilot,
  - Or pausing.

- [ ] After the call:
  - Update this projectâ€™s notes (for yourself).
  - Decide next steps:
    - Continue (paid),
    - Extend pilot,
    - Pause.

---

## After the pilot

If continuing:

- [ ] Agree on pricing and billing approach.
- [ ] Clarify who maintains the master data file.
- [ ] Confirm how often data sync should run.

If not continuing:

- [ ] Confirm data export requirements (if any).
- [ ] Disable or de-schedule tasks.
- [ ] Remove access if requested.
