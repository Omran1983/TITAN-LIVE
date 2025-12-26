# AION-ZERO Hardening Verification Checklist

### A. Core Safety & Hygiene (Phase 1)

**1.1 Panic-Stop / Global Kill Switch**

* [ ] Confirm file exists: `F:\AION-ZERO\scripts\Panic-Stop.ps1`
* [ ] Confirm it **creates** `F:\AION-ZERO\JARVIS.PANIC.LOCK` (dry-run in test env)
* [ ] Confirm it **does NOT** delete or modify `.env`
* [ ] Confirm it only targets expected processes (PowerShell + Python)
* [ ] Confirm `Jarvis-LoadEnv.ps1` refuses to start when `JARVIS.PANIC.LOCK` exists
* [ ] Confirm unlock procedure: manually deleting `JARVIS.PANIC.LOCK` restores normal startup

**1.2 Supervisor / Watchdog**

* [ ] File exists: `F:\AION-ZERO\scripts\Jarvis-Watchdog.ps1`
* [ ] `Jarvis-CommandsApi` health endpoint returns `status=ok` when system is running
* [ ] Watchdog detects a stopped `Jarvis-RunLoop-*` task within 20 minutes
* [ ] Watchdog automatically restarts a deliberately-stopped RunLoop task
* [ ] Any restart is logged (location: log file or DB)

**1.3 Commands API Security**

* [ ] File exists: `F:\AION-ZERO\scripts\Jarvis-CommandsApi.ps1`
* [ ] `.env` contains `AZ_COMMANDS_API_KEY` (or equivalent)
* [ ] Requests **without** `X-API-KEY` are rejected (HTTP 401/403)
* [ ] Requests with incorrect `X-API-KEY` are rejected
* [ ] Valid key works and command is queued in `az_commands`

---

### B. Intelligence Hardening (Phase 2)

**2.1 Jarvis-CodeAgent.ps1**

* [ ] File exists & is referenced wherever code patches are triggered
* [ ] JSON schema lock in place (bad JSON → fails safely, no file changes)
* [ ] Attempts to modify `.env` are rejected
* [ ] Attempts to modify `Panic-Stop.ps1` are rejected
* [ ] Attempts to modify paths containing `...` or outside allowed root are rejected
* [ ] Valid, schema-correct patches are applied and logged
* [ ] Every modified file receives `# AION-ZERO-SIG:` signature from `fingerprint.py`

---

### C. Financial Control (Phase 3)

**3.1 Ledger & Budget**

* [ ] `F:\AION-ZERO\sql\az_ledger.sql` applied, table `az_ledger` exists
* [ ] `Jarvis-Ledger.ps1` present and imported where LLM calls occur
* [ ] `.env` or envvars define `AZ_BUDGET_CAP_USD` (default $5)
* [ ] When cumulative cost < cap → calls allowed
* [ ] When cumulative cost ≥ cap → further LLM calls blocked and logged
* [ ] Daily reset behaviour defined and working (new day → fresh budget)

---

### D. GraphRAG Intelligence (Phase 4)

* [ ] `az_graph.sql` applied: nodes, edges, communities tables exist
* [ ] `graph_builder.py` can scan `F:\AION-ZERO` for Python, PS1, SQL references
* [ ] GraphBuilder worker task exists: `Jarvis-GraphBuilderWorker`
* [ ] External docs crawler can run with no crashes (even if target offline)
* [ ] Safety scanner rejects malicious / obfuscated payloads (test with a simple “eval”/`os.system` sample)
* [ ] “Changing Jarvis-Ledger.ps1 affects CodeAgent” is represented in the graph (at least 1 dependency edge)

---

### E. Citadel (Phase 6)

* [ ] `Jarvis-Citadel.ps1` exists and starts backend (`citadel/main.py`)
* [ ] Citadel reachable at `http://localhost:9000`
* [ ] Health widget shows: CommandsApi, Watchdog, RunLoops, Reflex, RevenueGen, DocGen states
* [ ] Financial dashboard displays today’s spend from `az_ledger`
* [ ] Reflex incident log visible and filtered by date/status

---

### F. Autonomous Ops & Revenue (Phase 7)

* [ ] `Jarvis-RevenueGenerator.ps1` registered as hourly task
* [ ] At least one ReachX/OKASINA/EduConnect job successfully auto-commissioned and executed
* [ ] `Jarvis-DocGen.ps1` registered weekly; `F:\AION-ZERO\reports\` contains generated whitepaper/report
* [ ] `fingerprint.py` signs generated files (`# AION-ZERO-SIG:` present and verifiable)
