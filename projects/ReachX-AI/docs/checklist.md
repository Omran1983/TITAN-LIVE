# ReachX AI — Build Checklist (V1)

## PHASE 0 — Foundation
[ ] Confirm brand name.
[ ] Register domain.
[ ] Draft MSA (Master Service Agreement).
[ ] Draft DPA (Data Processing Agreement).
[ ] Draft Privacy Policy.
[ ] Draft Automated Communication Consent.

## PHASE 1 — Architecture & Data
[ ] Finalise high-level architecture (hybrid: local + cloud).
[ ] Confirm tech stack (Supabase, n8n, Jarvis/AZ, Cloudflare Worker).
[ ] Create Supabase project (reachx-ai).
[ ] Create base tables: clients, campaigns, leads, interactions, users.

## PHASE 2 — Infra Setup
[ ] Create F:\ReachX-AI folder structure.
[ ] Run n8n once via Docker to confirm it works.
[ ] Connect n8n to Supabase (test workflow).
[ ] Set up log folders and basic cleanup script.

## PHASE 3 — Lead Engine
[ ] Implement first scraper (single source) via Jarvis/AZ.
[ ] Insert sample leads into Supabase.
[ ] Implement lead cleaning & scoring.
[ ] Implement deduplication logic.

## PHASE 4 — Outbound Engine
[ ] Connect email provider (SMTP/Resend/SES).
[ ] Create email templates for EN / FR / MFE / HI / UR.
[ ] Build n8n email sequence workflow.
[ ] Design and implement Call Engine (human-first UI).
[ ] Save call outcomes into interactions table.

## PHASE 5 — CRM & Reporting
[ ] Implement Excel/ODS export from Supabase.
[ ] Build basic client dashboard (stats + list of leads).
[ ] Implement daily summary report (email/Telegram).

## PHASE 6 — Test & Launch
[ ] Run internal test campaign with dummy data.
[ ] Fix errors, tune scoring & templates.
[ ] Onboard first beta client.
[ ] Run small real campaign (50–100 leads).
[ ] Collect feedback and refine.

## PHASE 7 — Scale & Bot-Ready
[ ] Add proper RLS and multi-client isolation in Supabase.
[ ] Add per-client quotas and settings.
[ ] Define Call Engine integration for future AI bot (Twilio/SIP etc).
[ ] Prepare industry-specific packs (recruitment, hospitality, logistics, etc).

