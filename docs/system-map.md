# AION-ZERO System Map – F:\ Drive (v1)

This file is the SINGLE SOURCE OF TRUTH for everything on F:\  
We update this as we go. Nothing gets created or deleted without passing through here.

Last updated: 2025-12-05

---

## 1. Legend

**RAG (Status)**  
- 🟥 Red   = Not started / unclear / legacy  
- 🟧 Amber = In progress / prototype / messy  
- 🟩 Green = Working & in use  

**Owner**  
- [O] = Omran  
- [J] = JARVIS / AZ / bots  
- [O+J] = Shared

---

## 2. Top-Level F:\ Overview

### 2.1 Core Infra & Control

| Path                | Description                                      | Status | Owner |
|---------------------|--------------------------------------------------|--------|-------|
| `F:\AION-ZERO`      | Main infra + orchestrator (Control Center home)  | 🟧     | [O+J] |
| `F:\Jarvis`         | JARVIS core (LLM/logic glue)                     | 🟧     | [J]   |
| `F:\Jarvis-Desktop-Agent` | Desktop automation (mouse/keyboard workflows) | 🟧 | [J]   |
| `F:\Jarvis-LocalOps`| Local command/ops runner (docker/agents/etc.)    | 🟧     | [J]   |
| `F:\PowerShell`     | PS scripts & tools (Jarvis, backups, ops)        | 🟧     | [J]   |
| `F:\secrets`        | Sensitive config/secrets                         | 🟧     | [O]   |
| `F:\Backups`        | Backups (DB/json/logs)                           | 🟧     | [J]   |
| `F:\Logs`           | Log files from agents/tools                      | 🟧     | [J]   |

> **Rule:** AION-ZERO + Jarvis* + PowerShell = **Control Center + Bots**. These must be treated as **production infra**, not experiments.

---

### 2.2 Active Product / Project Folders

[Inference] Based on names and past chats.

| Path                           | Description                                              | Status | Owner |
|--------------------------------|----------------------------------------------------------|--------|-------|
| `F:\ReachX-AI`                 | ReachX core app (current pilot UI/API)                  | 🟧     | [O+J] |
| `F:\ReachX-Pilot-Project`     | Older/experimental ReachX pilot                          | 🟥     | [J]   |
| `F:\EduConnect`                | EduConnect / training platform                          | 🟥     | [O+J] |
| `F:\delivery_crm`              | Legacy delivery CRM (pre-AION-ZERO)                     | 🟥     | [J]   |
| `F:\Jules Trading Platfrom`   | Trading / training / Jules project                      | 🟥     | [O+J] |
| `F:\Antigravity`               | Antigravity tooling (deployment/build)                  | 🟥     | [J]   |
| `F:\autopilot`                 | Automation/“autopilot” experiments                      | 🟥     | [J]   |
| `F:\Dev`                       | General dev sandbox                                      | 🟥     | [J]   |
| `F:\Workspaces`                | Editor/workspace configs (VS Code, etc.)                | 🟧     | [J]   |

> **Decision rule:**  
> - If a folder represents a **product with revenue potential** → we standardise it as a proper repo.  
> - If it’s an experiment → we either archive it or migrate what’s useful into `AION-ZERO`.

---

### 2.3 Support / System / Misc Folders

| Path                          | Description                                                | Status | Owner |
|-------------------------------|------------------------------------------------------------|--------|-------|
| `F:\_Consolidated`            | [Inference] Mixed stuff, manually consolidated            | 🟥     | [J]   |
| `F:\_Ops`                     | [Inference] Ops notes, scripts, maybe misc tools          | 🟥     | [J]   |
| `F:\Archive`                  | Old / frozen projects                                     | 🟧     | [J]   |
| `F:\.pnpm-store`              | PNPM package cache                                        | 🟩     | [J]   |
| `F:\OllamaData`               | Ollama models/cache                                       | 🟩     | [J]   |
| `F:\StabilityMatrix-win-x64`  | StabilityMatrix binary/build                              | 🟥     | [J]   |
| `F:\Releases`                 | Built artefacts / release builds                          | 🟥     | [J]   |
| `F:\tmp`                      | Temporary files                                           | 🟥     | [J]   |
| `F:\tweakops`                 | [Inference] Ops tuning/experiments                        | 🟥     | [J]   |

---

## 3. Foundation Checklist (What We Do With These Folders)

### 3.1 Promote to Proper Repos

These MUST be treated as first-class repos with Git, docs, and clean structure:

1. `F:\AION-ZERO`
2. `F:\ReachX-AI`
3. `F:\EduConnect`
4. `F:\Jules Trading Platfrom`
5. `F:\delivery_crm` (if we decide to resurrect or merge into ReachX/Deliveries)
6. `F:\Antigravity` (if still relevant)
7. `F:\Jarvis`
8. `F:\Jarvis-Desktop-Agent`
9. `F:\Jarvis-LocalOps`

**Tasks**

- [J] For each folder above:
  - Check if `.git` exists. If not, initialize: `git init`.
  - Ensure standard structure:
    - `README.md`
    - `docs/`
    - `src/`
    - `scripts/`
    - `config/` (TOML config)
  - Add `.gitignore` and `.env.example`.

- [O] For each **product repo** (ReachX, EduConnect, Jules, Deliveries):
  - Write a **one-paragraph description** in `README.md`:
    - What problem it solves  
    - Who it’s for  
    - How it makes money  

### 3.2 Archive / Clean Up

Folders likely to become storage only:

- `F:\Archive`
- `F:\Releases`
- `F:\tmp`
- `F:\_Consolidated`
- `F:\_Ops`

**Tasks**

- [J] Create subfolders inside `F:\Archive`:
  - `projects/`
  - `logs/`
  - `old-configs/`
- [J] Move **dead/failed** project copies from roots into `F:\Archive\projects`.
- [O] During a review session, mark in a simple text file:
  - Which archived projects are **never to be revived**  
  - Which ones have **IP or assets** we might later port into AION-ZERO.

---

## 4. Control Center Integration Plan (Per Folder)

### 4.1 AION-ZERO

**Role:**  
- Home of Control Center API + UI  
- Configuration of bots  
- Global RAG + Board data  

**Tasks**

- [J] Add:
  - `docs/system-map.md` (this file)  
  - `docs/rag-control-center.md` (RAG and roadmap for the Control Center itself)
- [O] Approve folder policy:
  - Nothing under AION-ZERO is “toy” or “temporary”.  
  - Experiments go into `F:\Dev`, not here.

---

### 4.2 Jarvis / Jarvis-* / PowerShell

**Role:**  
- Actual workers / agents  

**Tasks**

- [J] Register each in a **Bot Registry** (inside AION-ZERO DB or config):
  - `jarvis-core`
  - `jarvis-desktop-agent`
  - `jarvis-localops-agent`
  - `ps-tooling` (PowerShell toolbox)
- [J] For each bot:
  - Define capabilities (`powershell.run`, `sql.run`, `http.call`, etc.)
  - Implement heartbeat to Control Center.
- [O] Decide:
  - ✅ Which folders / commands are allowed to be automated  
  - ❌ Which operations are off-limits (e.g. no direct money transfers without explicit approval).

---

### 4.3 Product Folders (ReachX, EduConnect, Jules, delivery_crm)

For each:

- [O] Decide **status**:
  - `active`, `pause`, `archive`.
- [J] Add an entry in a `projects` manifest (JSON or DB table) under AION-ZERO:
  - `name`, `path`, `status`, `primary_kpi`, `owner_director`.

Example entry:

```json
{
  "id": "reachx",
  "name": "ReachX-AI",
  "path": "F:\\ReachX-AI",
  "status": "active",
  "primary_kpi": "Monthly revenue from placements",
  "board_owner": "Director of Workforce Systems"
}
