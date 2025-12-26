# ReachX Pilot Project

This folder contains everything needed to run, market and deploy the ReachX 14-Day Pilot for recruitment / manpower agencies, including:

- Client-facing documentation
- Data templates
- Marketing copy (flyers, landing page, outreach)
- Operational runbook and script map
- Draft legal & privacy notes

## Purpose

ReachX provides a monitored operations cockpit for agencies managing workers, employers and dormitories.  
The goal of the pilot is to replace spreadsheet chaos with a live, reliable dashboard in less than 14 days.

## What the pilot proves

The 14-day pilot is designed to show that:

1. Your existing Excel/CSV structure can be mapped into a proper database.
2. Your team can view workers, employers and dormitories from one simple dashboard.
3. The system can be monitored so that failures are visible, not silent.
4. We can support your operations remotely, without needing to install complex software at your premises.

## Folder Overview

- `docs/`  
  One-pager, data template guide, reliability pattern and deployment checklist.

- `marketing/`  
  A4 flyer copy, landing page content, outreach messages for WhatsApp, LinkedIn and email.

- `client-assets/`  
  CSV templates for workers, employers and dormitories. These are what you send to the client to fill.

- `ops/`  
  Map of Jarvis/ReachX scripts and a pilot runbook (what to do before, during and after a trial).

- `legal/`  
  Draft pilot agreement outline and privacy notes (to refine with a lawyer before large-scale use).

## Current Status (template)

You can update this section before each pilot:

- Technical state:
  - Database: Supabase project: [PROJECT_NAME_HERE]
  - Dashboard URL: [DASHBOARD_URL_HERE]
  - Heartbeat / Autopilot / UI ping: Installed and running.

- Commercial state:
  - Pilot client: [CLIENT_NAME_HERE]
  - Pilot window: [START_DATE] to [END_DATE]
  - Contact person: [CONTACT_NAME + ROLE]

## How to use this project

1. Read `docs/01-ReachX-Pilot-OnePager.md` before you talk to any client.
2. Use `docs/02-Data-Template-Guide.md` and the CSVs in `client-assets/` to collect or map data.
3. When preparing a new pilot, walk through `docs/04-Deployment-Checklist.md`.
4. Use the files in `marketing/` to create flyers, landing pages and outreach messages.
5. Use `ops/` internally to keep track of scripts, monitoring and pilot operations.
6. Use `legal/` as a starting point for agreements and privacy communication (with legal review).

This folder is the single source of truth when preparing or running ReachX pilots for local or international clients.
