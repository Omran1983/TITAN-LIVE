# ReachX AI — Data Model (Draft V1)

## Table: clients
- id (uuid, pk)
- name (text)
- contact_email (text)
- phone (text)
- status (text: active/inactive)
- created_at (timestamptz, default now())

## Table: campaigns
- id (uuid, pk)
- client_id (uuid, fk -> clients.id)
- name (text)
- target_industry (text)
- target_countries (text or json)
- languages (json: ["en","fr","mfe","hi","ur"])
- status (text: draft/running/paused/completed)
- created_at (timestamptz, default now())

## Table: leads
- id (uuid, pk)
- client_id (uuid, fk -> clients.id)
- campaign_id (uuid, fk -> campaigns.id)
- company_name (text)
- contact_name (text)
- role (text)
- email (text)
- phone (text)
- website (text)
- country (text)
- industry (text)
- language (text)
- score (text: hot/warm/cold)
- source (text: linkedin/web/manual/other)
- status (text: new/emailed/called/interested/not_interested/followup)
- created_at (timestamptz, default now())

## Table: interactions
- id (uuid, pk)
- lead_id (uuid, fk -> leads.id)
- campaign_id (uuid, fk -> campaigns.id)
- type (text: email/call/note/whatsapp)
- channel_id (text: e.g. "gmail", "myt", "sms")
- direction (text: outbound/inbound)
- language (text)
- summary (text)
- outcome (text: sent/opened/replied/no_answer/interested/not_interested/call_back)
- created_at (timestamptz, default now())

## Table: users
- id (uuid, pk)
- client_id (uuid, nullable, fk -> clients.id)
- name (text)
- email (text)
- role (text: admin/client_user)
- created_at (timestamptz, default now())

## Notes
- Indexes to add later on:
  - leads: client_id, campaign_id, status, created_at
  - interactions: lead_id, campaign_id, type, created_at
- Multi-client support from day one using client_id everywhere.
