# ReachX Reliability Pattern (Internal Notes)

This document explains, in simple terms, how we keep the ReachX pilot from failing silently.

Use this as:

- Talking points with clients.
- A reference when checking or improving the monitoring setup.
- Documentation of why the scripts exist.

---

## 1. Core idea

We cannot guarantee that "nothing ever breaks".  
We can guarantee that **we will know** when something important is broken.

We do this by monitoring three things:

1. The **database** (Supabase / Postgres)
2. The **data sync jobs** (Autopilot / Refresh scripts)
3. The **dashboard UI** (Cloudflare Pages)

If any one of these fails, we have logs and status signals.

---

## 2. Components

### a) Database Heartbeat

Scheduled script (e.g. `ReachX-Heartbeat.ps1`) checks:

- Can we reach the Supabase URL?
- Can we run simple queries against key tables?
- What are the row counts in:
  - `employers`
  - `workers`
  - `dormitories`

It logs a line like:

- `status=OK employers=2 workers=36 dormitories=2`, or
- `status=PARTIAL_ERROR employers=-1 workers=-1 dormitories=-1` if there are issues.

This gives us a quick way to see if the database is healthy and has data.

### b) Autopilot Sync

Scheduled script (e.g. `ReachX-Autopilot.ps1`) runs:

1. Heartbeat first, to confirm the database is reachable.
2. Then calls the data refresh script (e.g. `ReachX-Refresh-All.ps1`) which:
   - Reads from `workers-normalised.csv` (or similar).
   - Inserts new rows into `public.workers`.

For pilots we typically use **insert-only** mode for safety.  
Later, we can introduce smarter refresh logic (update vs insert).

The Autopilot script logs:

- When it starts.
- When it calls Heartbeat and whether that succeeded.
- When it calls Refresh-All and whether that succeeded.
- When it completes.

### c) UI Ping

Scheduled script (e.g. `ReachX-UI-Ping.ps1`) hits the Cloudflare Pages URL, for example:

- `https://XXXX.reachx-workers-ui.pages.dev/employers.html`

It records:

- HTTP status code (e.g. 200 OK, 308 redirect).
- Simple status label such as `UP` or `UP-REDIRECT`.

This tells us whether the public-facing dashboard is reachable and responding.

---

## 3. Logs and Status Script

We keep simple log files per component, for example:

- `reachx-heartbeat.log`
- `reachx-autopilot.log`
- `reachx-ui-ping.log`

These logs are stored on your machine (for example under `F:\Jarvis\logs\`).

We also maintain a small status script:

- `ReachX-Status.ps1`

When run, it prints a snapshot like:

- Last Heartbeat line
- Last Autopilot line
- Last UI Ping line

This gives a quick summary without manually opening each log.

---

## 4. How to explain this to clients

When a client asks "what if it fails?", you can say:

- We have basic monitoring in place for:
  - Database,
  - Sync jobs,
  - Dashboard availability.

- We log every run of the key scripts.

You can explain it in simple terms:

> "We design the system so that if something fails, we see a signal.  
> We do not rely on someone just noticing that data looks wrong a week later."

This is more honest than promising 100% perfection, while still showing that you care about reliability.

---

## 5. Future improvements

Later, this pattern can be extended with:

- Automatic alerts:
  - Email,
  - WhatsApp messages,
  - Or inserting rows into a "problems" table.

- Small internal status dashboard for:
  - Multiple clients,
  - Multiple pilots.

- Integration with ticketing systems or a simple internal "issues" list.

For now, the combination of logs + status script is enough for pilots and early clients.
