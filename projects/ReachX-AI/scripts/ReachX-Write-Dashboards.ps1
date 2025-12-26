param()

$envFile = "F:\ReachX-AI\.env"
$uiRoot  = "F:\ReachX-AI\infra\ReachX-Workers-UI-v1"

# ---------------------------------------------------------------------
# Read Supabase env
# ---------------------------------------------------------------------
$SUPABASE_URL      = $null
$SUPABASE_ANON_KEY = $null

Get-Content $envFile | ForEach-Object {
    if ($_ -match '=') {
        $parts = $_.Split('=',2)
        $key   = $parts[0].Trim()
        $val   = $parts[1].Trim()
        switch ($key) {
            "SUPABASE_URL"      { $SUPABASE_URL      = $val }
            "SUPABASE_ANON_KEY" { $SUPABASE_ANON_KEY = $val }
        }
    }
}

if (-not $SUPABASE_URL -or -not $SUPABASE_ANON_KEY) {
    Write-Error "Could not read SUPABASE_URL / SUPABASE_ANON_KEY from $envFile"
    exit 1
}

# ---------------------------------------------------------------------
# Shared CSS (single-quoted here-string)
# ---------------------------------------------------------------------
$baseCss = @'
    :root { color-scheme: dark; }
    body {
      font-family: system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
      margin: 0;
      padding: 24px;
      background: #020617;
      color: #e5e7eb;
    }
    h1 {
      margin: 0 0 4px 0;
      font-size: 22px;
    }
    .subtitle {
      font-size: 13px;
      color: #9ca3af;
      margin-bottom: 4px;
    }
    .summary {
      font-size: 13px;
      color: #fbbf24;
      margin-bottom: 8px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
      margin-top: 4px;
      background: #020617;
      border-radius: 8px;
      overflow: hidden;
    }
    th, td {
      padding: 8px 6px;
      border-bottom: 1px solid #1f2937;
      text-align: left;
      white-space: nowrap;
    }
    th {
      background: #020617;
      color: #9ca3af;
      font-weight: 500;
    }
    tr:nth-child(even) { background: #020617; }
    tr:hover td { background: #02081f; }
    .center { text-align: center; color: #6b7280; }
    .pill {
      padding: 2px 8px;
      border-radius: 999px;
      font-size: 11px;
      border: 1px solid #1f2937;
    }
    .status-open     { background:#451a03; color:#fed7aa; }
    .status-progress { background:#1e293b; color:#e5e7eb; }
    .status-done     { background:#022c22; color:#6ee7b7; }
    .priority-high   { background:#450a0a; color:#fecaca; }
    .priority-med    { background:#1e293b; color:#e5e7eb; }
    .priority-low    { background:#022c22; color:#6ee7b7; }
    .status-active   { background:#022c22; color:#6ee7b7; }
    .status-paused   { background:#1e293b; color:#e5e7eb; }
    .status-archived { background:#450a0a; color:#fecaca; }
    #status {
      font-size: 12px;
      color: #9ca3af;
      margin-top: 8px;
    }
'@

# helper to inject CSS + Supabase vars into HTML templates
function Fill-Html {
    param(
        [string]$template
    )
    $out = $template.Replace('/*__BASE_CSS__*/', $baseCss)
    $out = $out.Replace('SUPABASE_URL_PLACEHOLDER', $SUPABASE_URL)
    $out = $out.Replace('SUPABASE_ANON_PLACEHOLDER', $SUPABASE_ANON_KEY)
    return $out
}

# =====================================================================
# employers.html – Employer Profiles (reachx_employer_summary)
# =====================================================================
$employersTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>ReachX Employers</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
/*__BASE_CSS__*/
  </style>
  <script src="lib/supabase.min.js"></script>
</head>
<body>
  <h1>ReachX Employers</h1>
  <div class="subtitle" id="subtitle">Loading employer profiles…</div>
  <div class="summary" id="summary">Employers: – | Requests: – | Workers requested / fulfilled: – / –</div>

  <table>
    <thead>
      <tr>
        <th>Employer</th>
        <th>Country</th>
        <th>Leads</th>
        <th>Requests (open / total)</th>
        <th>Workers (requested / fulfilled / pool)</th>
        <th>Active assignments</th>
        <th>Primary agent</th>
      </tr>
    </thead>
    <tbody id="rows">
      <tr><td colspan="7" class="center">Loading…</td></tr>
    </tbody>
  </table>

  <div id="status">Bootstrapping Supabase…</div>

  <script>
    (function () {
      const SUPABASE_URL = "SUPABASE_URL_PLACEHOLDER";
      const SUPABASE_ANON_KEY = "SUPABASE_ANON_PLACEHOLDER";

      const subtitleEl = document.getElementById("subtitle");
      const summaryEl  = document.getElementById("summary");
      const statusEl   = document.getElementById("status");
      const tbody      = document.getElementById("rows");

      function setStatus(msg) { if (statusEl) statusEl.textContent = msg; }
      function setSubtitle(msg) { if (subtitleEl) subtitleEl.textContent = msg; }
      function setSummary(msg) { if (summaryEl) summaryEl.textContent = msg; }
      function setEmpty(msg) {
        tbody.innerHTML = "";
        const tr = document.createElement("tr");
        const td = document.createElement("td");
        td.colSpan = 7;
        td.className = "center";
        td.textContent = msg;
        tr.appendChild(td);
        tbody.appendChild(tr);
      }

      if (!window.supabase) {
        setStatus("Supabase bundle NOT loaded – check lib/supabase.min.js");
        setEmpty("Supabase JS bundle not loaded.");
        return;
      }

      const client = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

      async function loadEmployers() {
        try {
          setStatus("Querying reachx_employer_summary…");

          const { data, error } = await client
            .from("reachx_employer_summary")
            .select("*")
            .order("country", { ascending: true })
            .order("employer_name", { ascending: true });

          if (error) {
            console.error(error);
            setStatus("Error loading employers.");
            setSubtitle("Error loading employers – check console.");
            setSummary("Employers: 0 | Requests: 0 | Workers requested / fulfilled: 0 / 0");
            setEmpty("Error.");
            return;
          }

          if (!data || data.length === 0) {
            setStatus("No employers.");
            setSubtitle("No employers found.");
            setSummary("Employers: 0 | Requests: 0 | Workers requested / fulfilled: 0 / 0");
            setEmpty("No employers.");
            return;
          }

          tbody.innerHTML = "";

          let totalEmp = data.length;
          let totalReq = 0;
          let totalWorkersReq = 0;
          let totalWorkersFul = 0;

          data.forEach(function (row) {
            totalReq         += row.total_requests || 0;
            totalWorkersReq  += row.workers_requested || 0;
            totalWorkersFul  += row.workers_fulfilled || 0;

            const tr = document.createElement("tr");

            const tdName = document.createElement("td");
            tdName.textContent = row.employer_name || "(no name)";
            tr.appendChild(tdName);

            const tdCountry = document.createElement("td");
            tdCountry.textContent = row.country || "-";
            tr.appendChild(tdCountry);

            const tdLeads = document.createElement("td");
            tdLeads.textContent = row.leads_count || 0;
            tr.appendChild(tdLeads);

            const tdReq = document.createElement("td");
            tdReq.textContent = (row.open_requests || 0) + " / " + (row.total_requests || 0);
            tr.appendChild(tdReq);

            const tdWorkers = document.createElement("td");
            tdWorkers.textContent =
              (row.workers_requested   || 0) + " / " +
              (row.workers_fulfilled   || 0) + " / " +
              (row.workers_in_pool     || 0);
            tr.appendChild(tdWorkers);

            const tdAssign = document.createElement("td");
            tdAssign.textContent = row.active_assignments || 0;
            tr.appendChild(tdAssign);

            const tdAgent = document.createElement("td");
            tdAgent.textContent = row.primary_agent_name || "-";
            tr.appendChild(tdAgent);

            tbody.appendChild(tr);
          });

          setSubtitle("Loaded " + totalEmp + " employers.");
          setSummary(
            "Employers: " + totalEmp +
            " | Requests: " + totalReq +
            " | Workers requested / fulfilled: " + totalWorkersReq + " / " + totalWorkersFul
          );
          setStatus("OK.");
        } catch (e) {
          console.error(e);
          setStatus("Unexpected error – check console.");
          setEmpty("Unexpected error.");
        }
      }

      loadEmployers();
    })();
  </script>
</body>
</html>
'@

$employersHtml = Fill-Html -template $employersTemplate
$employersFile = Join-Path $uiRoot "employers.html"
$employersHtml | Set-Content -Path $employersFile -Encoding utf8
Write-Host "Wrote employers.html"

# =====================================================================
# agents.html – Agent Performance (reachx_agent_performance)
# =====================================================================
$agentsTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>ReachX Agents</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
/*__BASE_CSS__*/
  </style>
  <script src="lib/supabase.min.js"></script>
</head>
<body>
  <h1>ReachX Agents</h1>
  <div class="subtitle" id="subtitle">Loading agent performance…</div>
  <div class="summary" id="summary">
    Agents: – | Leads (stored/live): – / – | Workers placed (stored/live): – / –
  </div>

  <table>
    <thead>
      <tr>
        <th>Agent</th>
        <th>Country</th>
        <th>City</th>
        <th>Status</th>
        <th>Leads (stored / live)</th>
        <th>Workers placed (stored / live)</th>
        <th>Live conv. %</th>
        <th>Last activity</th>
      </tr>
    </thead>
    <tbody id="rows">
      <tr><td colspan="8" class="center">Loading…</td></tr>
    </tbody>
  </table>

  <div id="status">Bootstrapping Supabase…</div>

  <script>
    (function () {
      const SUPABASE_URL = "SUPABASE_URL_PLACEHOLDER";
      const SUPABASE_ANON_KEY = "SUPABASE_ANON_PLACEHOLDER";

      const subtitleEl = document.getElementById("subtitle");
      const summaryEl  = document.getElementById("summary");
      const statusEl   = document.getElementById("status");
      const tbody      = document.getElementById("rows");

      function setStatus(msg) { if (statusEl) statusEl.textContent = msg; }
      function setSubtitle(msg) { if (subtitleEl) subtitleEl.textContent = msg; }
      function setSummary(msg) { if (summaryEl) summaryEl.textContent = msg; }
      function setEmpty(msg) {
        tbody.innerHTML = "";
        const tr = document.createElement("tr");
        const td = document.createElement("td");
        td.colSpan = 8;
        td.className = "center";
        td.textContent = msg;
        tr.appendChild(td);
        tbody.appendChild(tr);
      }

      function statusClass(s) {
        if (!s) return "pill";
        const v = s.toLowerCase();
        if (v === "active")   return "pill status-active";
        if (v === "paused")   return "pill status-paused";
        if (v === "archived") return "pill status-archived";
        return "pill";
      }

      if (!window.supabase) {
        setStatus("Supabase bundle NOT loaded – check lib/supabase.min.js");
        setEmpty("Supabase JS bundle not loaded.");
        return;
      }

      const client = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

      async function loadAgents() {
        try {
          setStatus("Querying reachx_agent_performance…");

          const { data, error } = await client
            .from("reachx_agent_performance")
            .select("*")
            .order("country", { ascending: true })
            .order("full_name", { ascending: true });

          if (error) {
            console.error(error);
            setStatus("Error loading agents.");
            setSubtitle("Error loading agents – check console.");
            setSummary("Agents: 0 | Leads (stored/live): 0 / 0 | Workers placed (stored/live): 0 / 0");
            setEmpty("Error.");
            return;
          }

          if (!data || data.length === 0) {
            setStatus("No agents.");
            setSubtitle("No agents found.");
            setSummary("Agents: 0 | Leads (stored/live): 0 / 0 | Workers placed (stored/live): 0 / 0");
            setEmpty("No agents.");
            return;
          }

          tbody.innerHTML = "";

          let totalAgents = data.length;
          let sumStoredLeads  = 0;
          let sumLiveLeads    = 0;
          let sumStoredWorkers= 0;
          let sumLiveWorkers  = 0;

          data.forEach(function (row) {
            const storedLeads   = row.leads_generated_counter || 0;
            const liveLeads     = row.leads_live              || 0;
            const storedWorkers = row.workers_placed_counter  || 0;
            const liveWorkers   = row.workers_live            || 0;

            sumStoredLeads   += storedLeads;
            sumLiveLeads     += liveLeads;
            sumStoredWorkers += storedWorkers;
            sumLiveWorkers   += liveWorkers;

            const tr = document.createElement("tr");

            const tdName = document.createElement("td");
            tdName.textContent = row.full_name || row.name || "(no name)";
            tr.appendChild(tdName);

            const tdCountry = document.createElement("td");
            tdCountry.textContent = row.country || "-";
            tr.appendChild(tdCountry);

            const tdCity = document.createElement("td");
            tdCity.textContent = row.city || "-";
            tr.appendChild(tdCity);

            const tdStatus = document.createElement("td");
            const pill = document.createElement("span");
            pill.className = statusClass(row.status);
            pill.textContent = row.status || "active";
            tdStatus.appendChild(pill);
            tr.appendChild(tdStatus);

            const tdLeads = document.createElement("td");
            tdLeads.textContent = storedLeads + " / " + liveLeads;
            tr.appendChild(tdLeads);

            const tdWorkers = document.createElement("td");
            tdWorkers.textContent = storedWorkers + " / " + liveWorkers;
            tr.appendChild(tdWorkers);

            const tdConv = document.createElement("td");
            tdConv.textContent = (row.live_conversion_pct != null)
              ? row.live_conversion_pct + " %"
              : "-";
            tr.appendChild(tdConv);

            const tdLast = document.createElement("td");
            tdLast.textContent = row.last_activity_at
              ? new Date(row.last_activity_at).toLocaleString()
              : "-";
            tr.appendChild(tdLast);

            tbody.appendChild(tr);
          });

          setSubtitle("Loaded " + totalAgents + " agents.");
          setSummary(
            "Agents: " + totalAgents +
            " | Leads (stored/live): " + sumStoredLeads + " / " + sumLiveLeads +
            " | Workers placed (stored/live): " + sumStoredWorkers + " / " + sumLiveWorkers
          );
          setStatus("OK.");
        } catch (e) {
          console.error(e);
          setStatus("Unexpected error – check console.");
          setEmpty("Unexpected error.");
        }
      }

      loadAgents();
    })();
  </script>
</body>
</html>
'@

$agentsHtml = Fill-Html -template $agentsTemplate
$agentsFile = Join-Path $uiRoot "agents.html"
$agentsHtml | Set-Content -Path $agentsFile -Encoding utf8
Write-Host "Wrote agents.html"

# =====================================================================
# requests.html – Requests Command Center (reachx_request_pipeline)
# =====================================================================
$requestsTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>ReachX Requests</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
/*__BASE_CSS__*/
  </style>
  <script src="lib/supabase.min.js"></script>
</head>
<body>
  <h1>ReachX Requests Command Center</h1>
  <div class="subtitle" id="subtitle">Loading request pipeline…</div>
  <div class="summary" id="summary">
    Requests: – | Open: – | Workers remaining: –
  </div>

  <table>
    <thead>
      <tr>
        <th>Employer</th>
        <th>Country</th>
        <th>Role / Skill</th>
        <th>Status</th>
        <th>Priority</th>
        <th>Qty (req / ful / rem)</th>
        <th>Fill %</th>
        <th>Needed by</th>
        <th>Primary agent</th>
      </tr>
    </thead>
    <tbody id="rows">
      <tr><td colspan="9" class="center">Loading…</td></tr>
    </tbody>
  </table>

  <div id="status">Bootstrapping Supabase…</div>

  <script>
    (function () {
      const SUPABASE_URL = "SUPABASE_URL_PLACEHOLDER";
      const SUPABASE_ANON_KEY = "SUPABASE_ANON_PLACEHOLDER";

      const subtitleEl = document.getElementById("subtitle");
      const summaryEl  = document.getElementById("summary");
      const statusEl   = document.getElementById("status");
      const tbody      = document.getElementById("rows");

      function setStatus(msg) { if (statusEl) statusEl.textContent = msg; }
      function setSubtitle(msg) { if (subtitleEl) subtitleEl.textContent = msg; }
      function setSummary(msg) { if (summaryEl) summaryEl.textContent = msg; }
      function setEmpty(msg) {
        tbody.innerHTML = "";
        const tr = document.createElement("tr");
        const td = document.createElement("td");
        td.colSpan = 9;
        td.className = "center";
        td.textContent = msg;
        tr.appendChild(td);
        tbody.appendChild(tr);
      }

      function statusPill(status) {
        const span = document.createElement("span");
        let cls = "pill ";
        if (!status) status = "open";

        const v = status.toLowerCase();
        if (v === "open")         cls += "status-open";
        else if (v === "in_progress") cls += "status-progress";
        else if (v === "fulfilled" || v === "closed" || v === "done") cls += "status-done";
        else cls += "status-progress";

        span.className = cls;
        span.textContent = status;
        return span;
      }

      function priorityPill(p) {
        const span = document.createElement("span");
        let cls = "pill ";
        if (!p) p = "medium";
        const v = p.toLowerCase();
        if (v === "high") cls += "priority-high";
        else if (v === "low") cls += "priority-low";
        else cls += "priority-med";
        span.className = cls;
        span.textContent = p;
        return span;
      }

      if (!window.supabase) {
        setStatus("Supabase bundle NOT loaded – check lib/supabase.min.js");
        setEmpty("Supabase JS bundle not loaded.");
        return;
      }

      const client = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

      async function loadRequests() {
        try {
          setStatus("Querying reachx_request_pipeline…");

          const { data, error } = await client
            .from("reachx_request_pipeline")
            .select("*")
            .order("priority", { ascending: true })
            .order("needed_by", { ascending: true });

          if (error) {
            console.error(error);
            setStatus("Error loading requests.");
            setSubtitle("Error loading requests – check console.");
            setSummary("Requests: 0 | Open: 0 | Workers remaining: 0");
            setEmpty("Error.");
            return;
          }

          if (!data || data.length === 0) {
            setStatus("No requests.");
            setSubtitle("No active requests.");
            setSummary("Requests: 0 | Open: 0 | Workers remaining: 0");
            setEmpty("No requests.");
            return;
          }

          tbody.innerHTML = "";

          let totalReq = data.length;
          let openReq  = 0;
          let totalRemaining = 0;

          data.forEach(function (row) {
            const statusVal = row.status || "open";
            const remaining = row.qty_remaining || 0;

            if (statusVal === "open" || statusVal === "in_progress") {
              openReq += 1;
              totalRemaining += remaining;
            }

            const tr = document.createElement("tr");

            const tdEmp = document.createElement("td");
            tdEmp.textContent = row.employer_name || "(no employer)";
            tr.appendChild(tdEmp);

            const tdCountry = document.createElement("td");
            tdCountry.textContent = row.request_country || row.employer_country || "-";
            tr.appendChild(tdCountry);

            const tdRole = document.createElement("td");
            const role = row.role || "-";
            const skill = row.requested_skill || "";
            tdRole.textContent = skill ? (role + " / " + skill) : role;
            tr.appendChild(tdRole);

            const tdStatus = document.createElement("td");
            tdStatus.appendChild(statusPill(statusVal));
            tr.appendChild(tdStatus);

            const tdPriority = document.createElement("td");
            tdPriority.appendChild(priorityPill(row.priority || "medium"));
            tr.appendChild(tdPriority);

            const tdQty = document.createElement("td");
            tdQty.textContent =
              (row.qty_requested || 0) + " / " +
              (row.qty_fulfilled || 0) + " / " +
              remaining;
            tr.appendChild(tdQty);

            const tdFill = document.createElement("td");
            tdFill.textContent =
              (row.fill_pct != null ? row.fill_pct : 0) + " %";
            tr.appendChild(tdFill);

            const tdNeeded = document.createElement("td");
            tdNeeded.textContent = row.needed_by
              ? new Date(row.needed_by).toLocaleDateString()
              : "-";
            tr.appendChild(tdNeeded);

            const tdAgent = document.createElement("td");
            tdAgent.textContent = row.primary_agent_name || "-";
            tr.appendChild(tdAgent);

            tbody.appendChild(tr);
          });

          setSubtitle("Loaded " + totalReq + " requests.");
          setSummary(
            "Requests: " + totalReq +
            " | Open: " + openReq +
            " | Workers remaining: " + totalRemaining
          );
          setStatus("OK.");
        } catch (e) {
          console.error(e);
          setStatus("Unexpected error – check console.");
          setEmpty("Unexpected error.");
        }
      }

      loadRequests();
    })();
  </script>
</body>
</html>
'@

$requestsHtml = Fill-Html -template $requestsTemplate
$requestsFile = Join-Path $uiRoot "requests.html"
$requestsHtml | Set-Content -Path $requestsFile -Encoding utf8
Write-Host "Wrote requests.html"

# =====================================================================
# country.html – Country Snapshot (reachx_country_snapshot)
# =====================================================================
$countryTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>ReachX Country Snapshot</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
/*__BASE_CSS__*/
  </style>
  <script src="lib/supabase.min.js"></script>
</head>
<body>
  <h1>ReachX Country Snapshot</h1>
  <div class="subtitle" id="subtitle">Loading countries…</div>
  <div class="summary" id="summary">
    Countries: – | Employers: – | Workers: – | Dorm free: –
  </div>

  <table>
    <thead>
      <tr>
        <th>Country</th>
        <th>Employers</th>
        <th>Agents</th>
        <th>Workers</th>
        <th>Leads</th>
        <th>Requests</th>
        <th>Workers (req / ful)</th>
        <th>Dorm (cap / occ / free)</th>
      </tr>
    </thead>
    <tbody id="rows">
      <tr><td colspan="8" class="center">Loading…</td></tr>
    </tbody>
  </table>

  <div id="status">Bootstrapping Supabase…</div>

  <script>
    (function () {
      const SUPABASE_URL = "SUPABASE_URL_PLACEHOLDER";
      const SUPABASE_ANON_KEY = "SUPABASE_ANON_PLACEHOLDER";

      const subtitleEl = document.getElementById("subtitle");
      const summaryEl  = document.getElementById("summary");
      const statusEl   = document.getElementById("status");
      const tbody      = document.getElementById("rows");

      function setStatus(msg) { if (statusEl) statusEl.textContent = msg; }
      function setSubtitle(msg) { if (subtitleEl) subtitleEl.textContent = msg; }
      function setSummary(msg) { if (summaryEl) summaryEl.textContent = msg; }
      function setEmpty(msg) {
        tbody.innerHTML = "";
        const tr = document.createElement("tr");
        const td = document.createElement("td");
        td.colSpan = 8;
        td.className = "center";
        td.textContent = msg;
        tr.appendChild(td);
        tbody.appendChild(tr);
      }

      if (!window.supabase) {
        setStatus("Supabase bundle NOT loaded – check lib/supabase.min.js");
        setEmpty("Supabase JS bundle not loaded.");
        return;
      }

      const client = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

      async function loadCountries() {
        try {
          setStatus("Querying reachx_country_snapshot…");

          const { data, error } = await client
            .from("reachx_country_snapshot")
            .select("*")
            .order("country", { ascending: true });

          if (error) {
            console.error(error);
            setStatus("Error loading countries.");
            setSubtitle("Error loading countries – check console.");
            setSummary("Countries: 0 | Employers: 0 | Workers: 0 | Dorm free: 0");
            setEmpty("Error.");
            return;
          }

          if (!data || data.length === 0) {
            setStatus("No countries.");
            setSubtitle("No country data found.");
            setSummary("Countries: 0 | Employers: 0 | Workers: 0 | Dorm free: 0");
            setEmpty("No data.");
            return;
          }

          tbody.innerHTML = "";

          let countCountries = data.length;
          let totalEmployers = 0;
          let totalWorkers   = 0;
          let totalDormFree  = 0;

          data.forEach(function (row) {
            totalEmployers += row.employers || 0;
            totalWorkers   += row.workers   || 0;
            totalDormFree  += row.dorm_free || 0;

            const tr = document.createElement("tr");

            const tdCountry = document.createElement("td");
            tdCountry.textContent = row.country || "-";
            tr.appendChild(tdCountry);

            const tdEmp = document.createElement("td");
            tdEmp.textContent = row.employers || 0;
            tr.appendChild(tdEmp);

            const tdAgents = document.createElement("td");
            tdAgents.textContent = row.agents || 0;
            tr.appendChild(tdAgents);

            const tdWorkers = document.createElement("td");
            tdWorkers.textContent = row.workers || 0;
            tr.appendChild(tdWorkers);

            const tdLeads = document.createElement("td");
            tdLeads.textContent = row.leads || 0;
            tr.appendChild(tdLeads);

            const tdReq = document.createElement("td");
            tdReq.textContent = row.requests || 0;
            tr.appendChild(tdReq);

            const tdWorkersReq = document.createElement("td");
            tdWorkersReq.textContent =
              (row.workers_requested || 0) + " / " +
              (row.workers_fulfilled || 0);
            tr.appendChild(tdWorkersReq);

            const tdDorm = document.createElement("td");
            tdDorm.textContent =
              (row.dorm_capacity || 0) + " / " +
              (row.dorm_occupied || 0) + " / " +
              (row.dorm_free || 0);
            tr.appendChild(tdDorm);

            tbody.appendChild(tr);
          });

          setSubtitle("Loaded " + countCountries + " countries.");
          setSummary(
            "Countries: " + countCountries +
            " | Employers: " + totalEmployers +
            " | Workers: " + totalWorkers +
            " | Dorm free: " + totalDormFree
          );
          setStatus("OK.");
        } catch (e) {
          console.error(e);
          setStatus("Unexpected error – check console.");
          setEmpty("Unexpected error.");
        }
      }

      loadCountries();
    })();
  </script>
</body>
</html>
'@

$countryHtml = Fill-Html -template $countryTemplate
$countryFile = Join-Path $uiRoot "country.html"
$countryHtml | Set-Content -Path $countryFile -Encoding utf8
Write-Host "Wrote country.html"

Write-Host "All dashboards written."
