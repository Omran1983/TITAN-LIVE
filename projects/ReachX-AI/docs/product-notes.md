# ReachX AI — Product Notes (V1)

## Core Promise
"We find B2B companies hiring, contact them in multiple languages, track everything, and hand you only hot leads to call."

## V1 Scope (MVP)
1. Scrape & collect B2B leads (company + contact + email + country + industry).
2. Auto-clean + score leads (HOT / WARM / COLD).
3. Send personalised emails in EN / FR / Mauritian Creole / Hindi / Urdu.
4. Create call list for human calling (script on screen).
5. Log call outcomes.
6. Sync data to Supabase + export to Excel/ODS.
7. Generate daily summary report for each client.

## Out of Scope for V1
- Full AI voice bot calling.
- Complex IVR trees.
- Client self-configuration of every parameter.
- High-frequency auto-dialer behaviour (predictive dialers etc).

## Architecture (High-Level)
- Local:
  - Jarvis / AION-ZERO for scraping, classification, AI text generation.
- Cloud:
  - Supabase for main database + storage.
  - n8n for workflow orchestration.
  - Cloudflare Worker (or later Vercel) for API + client dashboard.
- Client:
  - Any laptop/PC with browser access for dashboard.
  - Human calls via MyT/Emtel mobile or softphone.

## Call Engine (Design Principle)
We treat calling as a pluggable module.

**CallEngine.request (internal API)**

Input:
- lead_id
- phone
- language
- script_text

Output:
- outcome (interested / not_interested / no_answer / call_back)
- notes
- next_action (send_email / call_back / stop)

V1: handled by human caller (manual call, manual outcome selection).
V2: same interface, executed by voice bot.

