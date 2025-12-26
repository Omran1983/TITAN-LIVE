
import os
import re
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DB_URL = os.environ.get("JARVIS_DB_CONN")

# The Raw Text Dump (embedded for reliability, usually would read from file)
RAW_TEXT = r"""
## 🧠 AION-ZERO / TITAN OS Core

### 1) Jarvis Control Center API (FastAPI + Supabase)
* **What:** Single backend “control plane” for agents, jobs, configs, auth, telemetry.
* **Build pieces:** FastAPI app, auth (JWT), Supabase client, job runner hooks, audit logger.
* **Data/Interfaces:** tables: `az_agents`, `az_commands`, `az_jobs`, `az_job_runs`, `az_configs`, `az_audit_events`.
* **Steps:** scaffold FastAPI → add auth middleware → CRUD agents/commands/jobs → job execution (queue) → telemetry endpoints → RBAC.
* **Done when:** UI can start/stop agent, enqueue job, view runs/logs, enforce authority levels.

### 2) Agent Handoff Patterns (Commands + Flow Graphs)
* **What:** Multi-agent orchestration with explicit “handoff contracts.”
* **Build pieces:** `Command` object, `Handoff` record, flow DAG engine, retry/timeout policies.
* **Interfaces:** `az_graph_nodes`, `az_graph_edges`, `az_handoffs`, `az_command_runs`.
* **Steps:** define command schema → implement flow runner (topological exec) → per-node agent assignment → checkpointing → resumable runs.
* **Done when:** any workflow can pause/resume and switch agents without losing state.

### 3) Decision Fabric Enhancements (Authority + Audit Lock)
* **What:** Governance layer: who can do what, why, with immutable logs.
* **Build pieces:** authority ladder (L0–L4), policy evaluator, signed audit events, budget caps.
* **Interfaces:** `az_policies`, `az_authority_grants`, `az_budget_limits`, `az_decisions`, `az_decision_evidence`.
* **Steps:** define policies (YAML/TOML) → add evaluator in API → write-only audit append → tamper-evident hashing chain.
* **Done when:** every risky action has authority gate + traceable decision record.

### 4) Counterfactual Engine (Full Build)
* **What:** “What-if” simulator with stored alternative worlds.
* **Build pieces:** scenario schema, simulator runners, comparison UI, scoring.
* **Interfaces:** `az_counterfactual_worlds`, `az_counterfactual_runs`, `az_counterfactual_metrics`.
* **Steps:** define world inputs → run sim jobs (async) → compute KPI deltas → rank scenarios → export decision memo.
* **Done when:** you can compare 3+ plans with clear KPI deltas and recommended move.

### 5) Authority Protocol / Kill-Switch Framework
* **What:** Hard stop controls across all agents + budgets + unsafe actions.
* **Build pieces:** global kill flag, per-agent kill, per-job kill, “circuit breakers”.
* **Interfaces:** `az_killswitch`, `az_agent_state`, `az_rate_limits`.
* **Steps:** implement kill checks in every critical loop → add watchdog enforcement → add emergency UI switch → add auto-kill triggers.
* **Done when:** one switch reliably halts spend/actions within seconds.

### 6) Executive Dashboard (Citadel UI – missing module)
* **What:** “CEO view”: revenue, leads, ops health, agent performance.
* **Build pieces:** dashboard pages, KPI cards, time-series charts, drilldowns.
* **Interfaces:** read from `az_health_snapshots`, `az_leads`, `az_jobs`, finance tables.
* **Steps:** define KPI list → write `/api/kpi/*` endpoints → build React dashboard → add filters/time ranges.
* **Done when:** daily decisions can be made from one screen.

### 7) Finance Agent
* **What:** Agent that produces cashflow, runway, collections, pricing actions.
* **Build pieces:** ledger ingest, categorizer, KPI calculator, alert engine.
* **Interfaces:** `az_ledger_tx`, `az_finance_kpi_daily`, `az_finance_alerts`.
* **Steps:** normalize transactions → classify categories → compute KPIs → generate weekly actions → push alerts.
* **Done when:** weekly finance memo auto-generated with 3 actions + numbers.

### 8) Compliance Agent
* **What:** Ensures outputs/actions remain within rules (your constraints + legal + Islamic rules).
* **Build pieces:** rule engine, content/action validator, escalation workflow.
* **Interfaces:** `az_compliance_rules`, `az_compliance_checks`, `az_escalations`.
* **Steps:** encode rules → integrate pre-action checks → block/ask for override (authority) → log decisions.
* **Done when:** noncompliant actions are prevented by default.

### 9) Procurement Module
* **What:** Purchase requests → approvals → supplier quotes → PO tracking.
* **Build pieces:** PR workflow, quote collection, PO generator, delivery confirmation.
* **Interfaces:** `az_pr`, `az_quotes`, `az_suppliers`, `az_pos`, `az_receipts`.
* **Steps:** define workflow states → implement CRUD + approvals → email/whatsapp quote requests → PO PDF generator.
* **Done when:** you can request→approve→PO→receive with full audit trail.

### 10) Support Agent
* **What:** Central support inbox triage + auto-replies + ticketing.
* **Build pieces:** email/whatsapp ingestion, classifier, response templates, SLA tracker.
* **Interfaces:** `az_tickets`, `az_ticket_events`, `az_sla_policies`.
* **Steps:** connect channels → classify issue → draft reply → escalate if needed → measure SLA.
* **Done when:** inbound messages become tracked tickets with suggested responses.

### 11) Knowledge Base Agent
* **What:** Internal “truth store”: docs, policies, code notes, SOPs.
* **Build pieces:** ingestion, chunking, embeddings (optional), retrieval, citation.
* **Interfaces:** `az_kb_docs`, `az_kb_chunks`, `az_kb_sources`.
* **Steps:** ingest markdown/pdf/text → chunk → store → build search endpoint → integrate into agents.
* **Done when:** agents can answer with sources + you can search your own ops knowledge.

### 12) Encrypted Scar Federation (Licensing / Moat Layer)
* **What:** Your proprietary “decision traces” + policies as a licensable package.
* **Build pieces:** exportable policy bundles, signed logs, tenant packaging.
* **Interfaces:** `az_policy_packages`, `az_license_keys`, `az_tenant_configs`.
* **Steps:** formalize schema → build export/import → signature verification → per-tenant enforcement.
* **Done when:** you can ship a “governed agent OS” to clients as product.

## 🤖 Agent / Automation Extensions

### 13) NotebookLM-style ingestion agents (4 agents)
* **What:** pipeline: collect sources → decode media → chunk → normalize.
* **Build pieces:** `SourceHarvester`, `MediaDecoder`, `ContextChunker`, `FormatNormalizer`.
* **Interfaces:** `az_ingest_jobs`, `az_ingest_artifacts`.
* **Steps:** build each as idempotent worker → shared artifact format → retries + caching.
* **Done when:** any URL/video/doc becomes searchable chunks in KB.

### 14) MCP (Microsoft Learn) Integration
* **What:** Official docs context for .NET/Azure etc via MCP server.
* **Build pieces:** MCP client config, connector agent, caching.
* **Interfaces:** `az_knowledge_providers`, `az_provider_cache`.
* **Steps:** add provider registry → implement MCP query tool → cache results → cite in outputs.
* **Done when:** dev agents can fetch authoritative doc answers on demand.

### 15) Excel Agent Mode Integration (Oct 2025)
* **What:** Automated reporting into Excel with agent steps.
* **Build pieces:** report templates, export jobs, scheduled refresh.
* **Interfaces:** `az_reports`, `az_report_runs`.
* **Steps:** define template → write generator → schedule runs → push file outputs.
* **Done when:** daily/weekly reports generated automatically.

### 16) byLLM framework (meaning-typed programming)
* **What:** Strict schemas for prompts/tools to reduce hallucination + enforce outputs.
* **Build pieces:** typed I/O contracts, validators, adapters.
* **Interfaces:** `az_schemas`, `az_tool_specs`.
* **Steps:** define schemas → add validation layer → fail-fast → retries with constraints.
* **Done when:** agents rarely “freeform”; outputs are machine-parseable.

### 17) Ollama-based CLI enhancements (beyond current setup)
* **What:** Use local LLM for summarize/extract/classify in CLI tools.
* **Build pieces:** model router, prompt pack, caching.
* **Interfaces:** local file cache + `az_llm_runs`.
* **Steps:** standardize CLI contract → add `--llm` modes → add caching → log runs.
* **Done when:** CLI can run offline and still produce consistent outputs.

### 18) Multi-model arbitration layer (Ollama + Gemini burst)
* **What:** route tasks to cheapest/fastest model with quality checks.
* **Build pieces:** scoring, fallback policies, cost tracker.
* **Interfaces:** `az_model_routes`, `az_model_costs`.
* **Steps:** define decision rules → implement router → run verifier model on risky outputs.
* **Done when:** you get speed + quality + cost control automatically.

## 📈 Trading / Crypto Systems

### 19) Jules Trading Platform (Sharia-compliant)
* **What:** Automated strategy execution with strict halal constraints.
* **Build pieces:** rule engine, broker/exchange connector, risk manager.
* **Interfaces:** `az_strategies`, `az_orders`, `az_positions`, `az_risk_limits`.
* **Steps:** codify sharia constraints → paper trading → risk limits → small capital pilot.
* **Done when:** paper mode profitable + compliant + kill-switch proven.

### 20) Trading Assistant Workflow (TradingView → Webhook → AZ → ccxt)
* **What:** Alerts become structured trades + journaling.
* **Build pieces:** webhook receiver, signal parser, decision engine, ccxt executor (dry-run first).
* **Interfaces:** `az_signals`, `az_trade_decisions`, `az_trade_runs`.
* **Steps:** webhook endpoint → map signals → validate → simulate → optionally execute micro.
* **Done when:** signals reliably produce journaled decisions and simulated outcomes.

### 21) Crypto’s $1T Blind Spot Framework (Training module)
* **What:** Educational module + templates for macro-to-trade reasoning.
* **Build pieces:** curriculum pages, exercises, case studies, rubric.
* **Interfaces:** `edu_modules`, `edu_lessons`, `edu_assessments`.
* **Steps:** outline → build lessons → add quizzes → add “apply to trade plan” template.
* **Done when:** learners can produce a structured trade thesis from framework.

### 22) Capital Micro-Sovereignty / Escrow Pools
* **What:** controlled capital allocation with governance.
* **Build pieces:** escrow rules, approvals, allocation ledger.
* **Interfaces:** `az_capital_pools`, `az_allocations`, `az_escrow_events`.
* **Steps:** define pool types → approvals → allocation constraints → audit.
* **Done when:** money movement requires policy + authority.

### 23) Counterfactual Market Simulator
* **What:** simulate strategy performance under alt conditions.
* **Build pieces:** historical data loader, backtester, scenario modifiers.
* **Interfaces:** `az_backtests`, `az_sim_metrics`.
* **Steps:** ingest data → run backtests → apply scenario params → compare.
* **Done when:** you can compare variants with consistent metrics.

## 🧪 Infrastructure / Engineering

### 24) 10GbE Home Lab Upgrade (parked)
* **What:** network throughput for large datasets + local inference.
* **Build pieces:** NICs, switch, cabling, NAS tuning.
* **Steps:** pick topology → hardware buy list → configure jumbo frames → test throughput.
* **Done when:** stable sustained >800MB/s LAN transfers.

### 25) Hyper-tenancy DB model (many small DBs)
* **What:** isolate tenants cheaply; scale by sharding per client.
* **Build pieces:** tenant router, DB provisioning, migration runner.
* **Interfaces:** `az_tenants`, `az_tenant_dbs`.
* **Steps:** decide DB tech → implement router → migration per tenant → backup policy.
* **Done when:** onboarding new tenant is 1 command.

### 26) React/Next.js vulnerability bots
* **What:** automated security checks in CI + scheduled.
* **Build pieces:** dependency scanner, CVE alerts, PR gate.
* **Steps:** add CI job → nightly cron → alert to email/whatsapp → patch workflow.
* **Done when:** high severity fails builds and notifies you.

### 27) Durable async queue layer (global)
* **What:** move heavy work out of request path; guaranteed completion.
* **Build pieces:** queue, worker, retry, DLQ, idempotency keys.
* **Interfaces:** `az_queue_jobs`, `az_queue_runs`.
* **Steps:** pick queue (db-backed OK) → implement worker loop → idempotency → retries.
* **Done when:** all heavy tasks are queued; API stays fast.

### 28) VSCodium Safety Mode profile
* **What:** locked-down dev profile (extensions + settings).
* **Build pieces:** settings.json, extension list, policies.
* **Steps:** craft profile → export → script to apply.
* **Done when:** one command switches IDE into safe mode.

### 29) VS Code Full-Power profile
* **What:** maximum productivity profile.
* **Steps:** same as above with power extensions + settings.
* **Done when:** one command swaps profiles reliably.

### 30) Environment-aware IDE switching logic
* **What:** auto-switch based on project sensitivity or network state.
* **Build pieces:** detector script, profile switcher.
* **Steps:** read env flags → apply correct profile → log.
* **Done when:** it switches without you thinking.

## 🛍️ OKASINA / Business Systems

### 31) Remaining missing e-commerce modules (finance/procurement/executive roll-up)
* **What:** connect store ops into Titan dashboards.
* **Build pieces:** order KPI, inventory health, supplier costs, margin tracking.
* **Interfaces:** `orders`, `order_items`, `inventory`, `suppliers`, `finance_kpis`.
* **Steps:** define KPIs → build ETL into Titan tables → dashboard views.
* **Done when:** you see margin, stock risk, and cash needs weekly.

### 32) 7 AI tools stack (deferred)
* **What:** productized add-ons (copy, images, insights, support, etc.)
* **Build pieces:** tool registry + UI + billing flags.
* **Steps:** pick 7 → implement via registry → enforce quotas.
* **Done when:** tools are togglable per plan.

### 33) AI Customer Support Agent (OKASINA)
* **What:** handle WhatsApp/DM/order questions.
* **Build pieces:** FAQ KB + ticketing + order lookup.
* **Steps:** ingest FAQ → connect channels → response templates → escalation.
* **Done when:** 60–80% queries handled automatically.

### 34) Automated Supplier Price Intelligence
* **What:** watch supplier prices/availability.
* **Build pieces:** scraper/email parser, change detection, alerts.
* **Steps:** define suppliers → ingest price points → detect deltas → alert + suggested reorder.
* **Done when:** you get “buy now” alerts before stockouts.

### 35) End-to-End Marketing Automation Pack
* **What:** content plan → posting → leads → follow-ups.
* **Build pieces:** campaign templates, scheduler, lead capture, follow-up sequences.
* **Steps:** define offers → build landing forms → automate outreach sequences.
* **Done when:** leads come in daily without manual posting.

## 🧩 Data / Cleanup / Recovery

### 36) Advanced data-cleaning pipeline integration
* **What:** robust ETL cleaning reusable across projects.
* **Build pieces:** validators, dedupe, normalization, profiling.
* **Interfaces:** `az_data_jobs`, `az_data_quality_reports`.
* **Steps:** integrate library → standard job schema → reports dashboard.
* **Done when:** every dataset ingested gets quality scoring + fixes.

### 37) Revisit & salvage “Failed Projects” folder
* **What:** extract reusable modules + delete the rest.
* **Build pieces:** triage checklist, migration plan.
* **Steps:** inventory → classify (reuse/kill) → extract components → archive.
* **Done when:** only reusable modules survive; dead weight removed.

## 📰 Intelligence & Signals

### 38) Daily automated news + opportunity snapshot bot
* **What:** daily digest: business/AI/grants + actionable leads.
* **Build pieces:** web fetchers, dedupe, summarizer, scoring.
* **Interfaces:** `az_news_items`, `az_opportunities`, `az_digest_runs`.
* **Steps:** sources list → fetch → score → compile → deliver (email/WhatsApp).
* **Done when:** you receive 5–10 scored opportunities daily.

### 39) Market signal detection agent (funding + demand signals)
* **What:** detect “people are buying / hiring / funding now.”
* **Build pieces:** signals from job boards, product launches, ads libraries, forums.
* **Interfaces:** `az_signals`, `az_signal_scores`.
* **Steps:** choose sources → extract entities → score intent → recommend offers.
* **Done when:** it outputs weekly “what to sell” with proof links.

### 40) Competitive agent monitoring system
* **What:** watch competitors’ pricing/features/ads.
* **Build pieces:** monitors, diff engine, alerts.
* **Interfaces:** `az_competitors`, `az_comp_changes`.
* **Steps:** define competitor set → scrape snapshots → diff → notify.
* **Done when:** you get alerts within 24h of major changes.

## 🔒 Governance / Config Standards

### 41) Full TOML-based config migration (all services)
* **What:** predictable config layering + schema validation.
* **Build pieces:** `config/base.toml`, `config/env.local.toml`, env overrides, validator.
* **Steps:** implement loader → replace hardcoded constants → validate at boot.
* **Done when:** every service starts only with valid config.

### 42) Global secrets & environment layer audit
* **What:** ensure secrets not hardcoded, rotate where needed.
* **Build pieces:** env scan, secret manager plan, rotation checklist.
* **Steps:** scan repos → move secrets → rotate keys → add CI checks.
* **Done when:** no secrets in code + automated guardrails.

## ⚠️ Explicitly Parked: “Don’t touch until triggered”

### 43) Anything-style AI app builder (Titan-equivalent)
* **What:** no-code agent app builder.
* **Pieces:** UI builder + backend generator + deploy pipeline.
* **Steps:** only after core Control Plane stable + strong niche.
* **Done when:** build mini-apps from prompts reliably.

### 44) API monetization layer (general)
* **What:** pricing, auth tiers, metering, billing.
* **Pieces:** usage tracking + plans + Stripe (or alt).
* **Steps:** add usage logs → enforce quotas → add checkout.
* **Done when:** can charge per-seat or per-usage.

### 45) Agentic AI courses / KDnuggets material
* **What:** learning pack → only valuable when mapped to your build.
* **Steps:** extract patterns → convert into internal SOPs.
* **Done when:** patterns show up in your production agents.

### 46) Multi-agent architecture deep refactor (later phase)
* **What:** big refactor to multi-agent “properly.”
* **Steps:** only after current workflows profitable + stable.
* **Done when:** reliability improves, not complexity.

### 47) Resume “Option B GitHub App wiring”
* **What:** GitHub App-based automation integration.
* **Pieces:** app creds, webhook handlers, repo permissions.
* **Steps:** register app → webhook endpoints → event processing → agent tasks.
* **Done when:** issues/PRs trigger agents automatically.
"""

def parse_and_ingest():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    # 1. Clear old data (full refresh)
    cur.execute("TRUNCATE TABLE az_roadmap;")
    
    # 2. Regex Parsing
    current_cat = "General"
    
    # Split by lines
    lines = RAW_TEXT.split('\n')
    
    item = {}
    count = 0
    
    for line in lines:
        line = line.strip()
        if not line: continue
        
        # Category Detection
        if line.startswith("## "):
            current_cat = line.replace("## ", "").strip()
            # Clean emojis
            current_cat = re.sub(r'[^\w\s/]', '', current_cat).strip()
            continue
            
        # Item Header
        if line.startswith("### "):
            # Save previous if exists
            if item:
                save_item(cur, item)
                count += 1
                item = {}
                
            title_raw = line.replace("### ", "").strip()
            # Extract ID if present "1) ..."
            title = re.sub(r'^\d+\)\s*', '', title_raw)
            item['title'] = title
            item['category'] = current_cat
            item['status'] = 'parked' # Default
            if "Parked" in current_cat:
                item['status'] = 'stopped'
                
            continue
            
        # Attributes
        if line.startswith("* **What:**") or line.startswith("* **What:**"):
            item['description'] = line.split(":", 1)[1].strip()
        elif line.startswith("* **Build pieces:**") or line.startswith("* **Pieces:**"):
            item['build_pieces'] = line.split(":", 1)[1].strip()
        elif line.startswith("* **Data/Interfaces:**") or line.startswith("* **Interfaces:**"):
            item['interfaces'] = line.split(":", 1)[1].strip()
        elif line.startswith("* **Steps:**") or line.startswith("* **Implementation steps:**"):
            item['steps'] = line.split(":", 1)[1].strip()
        elif line.startswith("* **Done when:**"):
            item['done_condition'] = line.split(":", 1)[1].strip()
            
    # Save last one
    if item:
        save_item(cur, item)
        count += 1
        
    conn.commit()
    conn.close()
    print(f"✅ Ingested {count} Roadmap Items.")

def save_item(cur, item):
    sql = """
        INSERT INTO az_roadmap 
        (category, title, description, build_pieces, interfaces, steps, done_condition, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """
    cur.execute(sql, (
        item.get('category'),
        item.get('title'),
        item.get('description'),
        item.get('build_pieces'),
        item.get('interfaces'),
        item.get('steps'),
        item.get('done_condition'),
        item.get('status', 'parked')
    ))

if __name__ == "__main__":
    parse_and_ingest()
