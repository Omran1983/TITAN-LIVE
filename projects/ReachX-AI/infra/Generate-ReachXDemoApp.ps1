# File: Generate-ReachXDemoApp.ps1
# Purpose: Generate a polished ReachX demo UI (static HTML)

$uiRoot = "F:\ReachX-AI\ui"

if (-not (Test-Path $uiRoot)) {
    New-Item -ItemType Directory -Path $uiRoot | Out-Null
}

$htmlPath = Join-Path $uiRoot "reachx-demo-app.html"

$html = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>ReachX Workforce Cloud · Mauritius Demo</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    * { box-sizing: border-box; }

    :root {
      color-scheme: dark;
      --bg: #020617;
      --bg-soft: #020617;
      --panel: rgba(15,23,42,0.96);
      --panel-soft: rgba(15,23,42,0.94);
      --border: rgba(30,64,175,0.75);
      --border-soft: rgba(51,65,85,0.9);
      --text-main: #e5e7eb;
      --text-muted: #9ca3af;
      --accent-1: #38bdf8;
      --accent-2: #22c55e;
      --accent-3: #f97316;
      --accent-4: #a855f7;
    }

    body {
      margin: 0;
      padding: 0;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background:
        radial-gradient(circle at 0% 0%, #0f172a 0, #020617 45%, #020617 100%),
        radial-gradient(circle at 100% 100%, #111827 0, #020617 55%, #020617 100%);
      color: var(--text-main);
    }

    .shell {
      max-width: 1200px;
      margin: 22px auto 28px;
      padding: 16px 18px 22px;
      border-radius: 26px;
      background:
        radial-gradient(circle at 0 0, rgba(56,189,248,0.20) 0, rgba(15,23,42,0.98) 48%, rgba(15,23,42,0.98) 100%),
        linear-gradient(145deg, #020617, #020617 45%, #020617 100%);
      border: 1px solid rgba(15,23,42,0.9);
      box-shadow:
        0 40px 120px rgba(0,0,0,0.88),
        0 0 0 1px rgba(15,23,42,0.9);
    }

    /* TOP BAR ---------------------------------------------------------- */

    .topbar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 6px 4px 12px;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .brand-icon {
      width: 34px;
      height: 34px;
      border-radius: 14px;
      background:
        radial-gradient(circle at 30% 0, #f9fafb 0, #e5e7eb 22%, #0f172a 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 20px;
      box-shadow: 0 10px 26px rgba(15,23,42,0.8);
    }
    .brand-text-main {
      font-size: 18px;
      font-weight: 700;
      letter-spacing: 0.09em;
      text-transform: uppercase;
    }
    .brand-text-sub {
      font-size: 11px;
      color: #a5b4fc;
    }

    .top-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      font-size: 10px;
    }
    .chip {
      padding: 4px 9px;
      border-radius: 999px;
      border: 1px solid rgba(148,163,184,0.85);
      background: rgba(15,23,42,0.9);
      color: var(--text-muted);
      display: inline-flex;
      align-items: center;
      gap: 5px;
    }
    .chip strong {
      color: #e5e7eb;
      font-weight: 600;
    }
    .chip.accent {
      border-color: rgba(56,189,248,0.9);
      background: radial-gradient(circle at 0 0, rgba(56,189,248,0.32) 0, rgba(15,23,42,0.98) 55%);
      color: #e5e7eb;
    }

    /* HERO ------------------------------------------------------------- */

    .hero {
      margin-top: 4px;
      display: grid;
      grid-template-columns: 1.15fr 1.4fr;
      gap: 18px;
      align-items: stretch;
    }

    .hero-left {
      padding: 16px 16px 14px;
      border-radius: 22px;
      background:
        radial-gradient(circle at 0 0, rgba(34,197,94,0.24) 0, transparent 55%),
        radial-gradient(circle at 100% 0, rgba(56,189,248,0.28) 0, transparent 65%),
        linear-gradient(145deg, #020617, #020617 42%, #020617 100%);
      border: 1px solid rgba(34,197,94,0.65);
      box-shadow: 0 22px 60px rgba(15,23,42,0.9);
      position: relative;
      overflow: hidden;
    }
    .hero-left::after {
      content: "";
      position: absolute;
      inset: -60px;
      background: radial-gradient(circle at 120% 140%, rgba(8,47,73,0.9) 0, transparent 60%);
      opacity: 0.7;
      pointer-events: none;
    }
    .hero-left-inner {
      position: relative;
      z-index: 1;
    }
    .hero-title {
      font-size: 23px;
      font-weight: 800;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      margin-bottom: 4px;
    }
    .hero-subline {
      font-size: 12px;
      color: #e0f2fe;
      margin-bottom: 14px;
    }

    .hero-metrics {
      display: grid;
      grid-template-columns: repeat(3, minmax(0,1fr));
      gap: 8px;
      margin-bottom: 12px;
    }
    .hero-metric {
      border-radius: 16px;
      padding: 8px 9px 7px;
      background: rgba(15,23,42,0.96);
      border: 1px solid rgba(55,65,81,0.95);
      font-size: 10px;
    }
    .hero-metric-label {
      text-transform: uppercase;
      letter-spacing: 0.12em;
      color: var(--text-muted);
    }
    .hero-metric-main {
      margin-top: 5px;
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      gap: 3px;
    }
    .hero-metric-value {
      font-size: 19px;
      font-weight: 800;
      color: #f9fafb;
    }
    .hero-metric-foot {
      margin-top: 2px;
      color: #a5b4fc;
    }

    .hero-flow {
      margin-top: 8px;
      padding: 8px 9px;
      border-radius: 16px;
      background: rgba(15,23,42,0.96);
      border: 1px dashed rgba(75,85,99,0.95);
      font-size: 10px;
    }
    .flow-row {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      align-items: center;
      justify-content: center;
    }
    .flow-step {
      padding: 4px 9px;
      border-radius: 999px;
      background: rgba(15,23,42,0.96);
      border: 1px solid rgba(75,85,99,0.95);
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 10px;
      color: #e5e7eb;
    }
    .flow-step span {
      font-size: 13px;
    }
    .flow-arrow {
      font-size: 12px;
      color: rgba(148,163,184,0.9);
    }

    .hero-footnote {
      margin-top: 7px;
      font-size: 10px;
      color: var(--text-muted);
    }

    /* DASHBOARD PREVIEW ------------------------------------------------ */

    .hero-right {
      padding: 12px 12px 10px;
      border-radius: 22px;
      background: radial-gradient(circle at 0 0, rgba(56,189,248,0.16) 0, transparent 45%),
                  radial-gradient(circle at 100% 0, rgba(168,85,247,0.16) 0, transparent 55%),
                  linear-gradient(145deg, #020617, #020617 50%, #020617 100%);
      border: 1px solid rgba(37,99,235,0.75);
      box-shadow: 0 22px 60px rgba(15,23,42,0.9);
    }

    .dash-frame {
      border-radius: 18px;
      background: var(--panel);
      border: 1px solid rgba(30,64,175,0.7);
      padding: 9px 10px 10px;
      box-shadow: inset 0 0 0 1px rgba(15,23,42,0.9);
    }

    .dash-top {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
    }
    .dash-title-group {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }
    .dash-title {
      font-size: 13px;
      font-weight: 600;
    }
    .dash-sub {
      font-size: 10px;
      color: var(--text-muted);
    }
    .dash-badges {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      font-size: 10px;
    }
    .dash-badge {
      padding: 3px 8px;
      border-radius: 999px;
      border: 1px solid rgba(148,163,184,0.8);
      background: rgba(15,23,42,0.95);
      color: var(--text-muted);
    }
    .dash-badge.green {
      border-color: rgba(34,197,94,0.9);
      color: #bbf7d0;
      background: rgba(22,163,74,0.18);
    }

    .dash-tabs {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      padding: 5px;
      border-radius: 999px;
      background: rgba(15,23,42,0.96);
      border: 1px solid rgba(31,41,55,0.95);
      margin-bottom: 8px;
      font-size: 10px;
    }
    .dash-tab {
      padding: 4px 8px;
      border-radius: 999px;
      border: 1px solid transparent;
      background: transparent;
      color: var(--text-muted);
      display: inline-flex;
      align-items: center;
      gap: 5px;
      cursor: pointer;
    }
    .dash-tab span {
      font-size: 12px;
    }
    .dash-tab.active {
      border-color: rgba(56,189,248,0.8);
      background: radial-gradient(circle at 0 0, rgba(56,189,248,0.24) 0, rgba(15,23,42,0.98) 60%);
      color: #f9fafb;
      box-shadow: 0 8px 20px rgba(15,23,42,0.9);
    }

    .dash-main {
      display: grid;
      grid-template-columns: 1.35fr 1fr;
      gap: 8px;
      margin-top: 4px;
    }

    .dash-card {
      border-radius: 14px;
      background: var(--panel-soft);
      border: 1px solid var(--border-soft);
      padding: 7px 8px 7px;
      font-size: 10px;
    }
    .dash-card-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      margin-bottom: 4px;
    }
    .dash-card-title {
      font-size: 11px;
      font-weight: 600;
    }
    .dash-card-sub {
      font-size: 9px;
      color: var(--text-muted);
    }

    .dash-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 10px;
    }
    .dash-table th,
    .dash-table td {
      padding: 3px 4px;
      white-space: nowrap;
      text-align: left;
    }
    .dash-table th {
      text-transform: uppercase;
      letter-spacing: 0.13em;
      font-size: 9px;
      color: var(--text-muted);
      border-bottom: 1px solid rgba(55,65,81,0.95);
    }
    .dash-table tbody tr:nth-child(even) td {
      background: rgba(15,23,42,0.98);
    }
    .dash-table tbody tr:nth-child(odd) td {
      background: rgba(15,23,42,0.92);
    }

    .label-main {
      font-weight: 500;
      color: #f9fafb;
    }

    .score-chip {
      display: inline-flex;
      align-items: center;
      padding: 1px 6px;
      border-radius: 999px;
      border-width: 1px;
      border-style: solid;
      font-size: 9px;
      font-weight: 600;
    }
    .score-hot {
      background: rgba(248,113,113,0.18);
      color: #fecaca;
      border-color: rgba(248,113,113,0.7);
    }
    .score-warm {
      background: rgba(251,191,36,0.18);
      color: #fef3c7;
      border-color: rgba(251,191,36,0.7);
    }
    .score-cold {
      background: rgba(56,189,248,0.18);
      color: #e0f2fe;
      border-color: rgba(56,189,248,0.7);
    }

    .status-pill {
      padding: 1px 6px;
      border-radius: 999px;
      font-size: 9px;
      border: 1px solid rgba(34,197,94,0.7);
      background: rgba(22,163,74,0.18);
      color: #bbf7d0;
    }
    .status-pill.idle {
      border-color: rgba(148,163,184,0.8);
      background: rgba(31,41,55,0.96);
      color: var(--text-muted);
    }

    .mini-note {
      margin-top: 3px;
      font-size: 9px;
      color: var(--text-muted);
    }

    /* Mini "bar chart" for money/time */
    .bar-wrap {
      display: flex;
      gap: 6px;
      align-items: flex-end;
      margin-top: 6px;
      height: 70px;
    }
    .bar {
      flex: 1;
      border-radius: 999px 999px 4px 4px;
      background: linear-gradient(to top, rgba(15,23,42,0.9), rgba(15,23,42,0.9));
      position: relative;
      overflow: hidden;
    }
    .bar-inner {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      border-radius: 999px 999px 4px 4px;
      background: linear-gradient(to top, #22c55e, #a3e635);
    }
    .bar-inner.alt {
      background: linear-gradient(to top, #38bdf8, #e0f2fe);
    }
    .bar-label {
      position: absolute;
      top: 2px;
      left: 4px;
      right: 4px;
      font-size: 9px;
      color: #0f172a;
      text-align: center;
      font-weight: 600;
    }
    .bar-caption {
      margin-top: 3px;
      font-size: 9px;
      color: var(--text-muted);
      text-align: center;
    }

    /* BOTTOM STRIP ----------------------------------------------------- */
    .bottom-strip {
      margin-top: 16px;
      display: grid;
      grid-template-columns: 1.5fr 1.2fr;
      gap: 10px;
      font-size: 10px;
    }
    .bottom-card {
      border-radius: 18px;
      background: rgba(15,23,42,0.96);
      border: 1px solid rgba(31,41,55,0.95);
      padding: 10px 11px 9px;
    }
    .bottom-title {
      font-size: 12px;
      font-weight: 600;
      margin-bottom: 5px;
    }
    .bottom-list {
      display: grid;
      grid-template-columns: repeat(2,minmax(0,1fr));
      gap: 4px 10px;
    }
    .bottom-item {
      display: flex;
      gap: 6px;
      align-items: flex-start;
    }
    .bottom-icon {
      width: 16px;
      height: 16px;
      border-radius: 999px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 10px;
      background: rgba(31,41,55,0.96);
      border: 1px solid rgba(55,65,81,0.95);
    }
    .bottom-text-main {
      font-size: 10px;
      color: #e5e7eb;
    }
    .bottom-text-sub {
      font-size: 9px;
      color: var(--text-muted);
    }

    .bottom-right-rows {
      display: grid;
      gap: 6px;
    }
    .bottom-tag-row {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
    }
    .small-pill {
      padding: 3px 7px;
      border-radius: 999px;
      border: 1px solid rgba(55,65,81,0.95);
      background: rgba(15,23,42,0.96);
      color: var(--text-muted);
      font-size: 9px;
    }
    .small-pill strong {
      color: #e5e7eb;
    }

    @media (max-width: 1040px) {
      .shell { border-radius: 0; margin: 0; }
      .hero { grid-template-columns: 1fr; }
    }
    @media (max-width: 720px) {
      .hero-metrics { grid-template-columns: 1fr 1fr; }
      .dash-main { grid-template-columns: 1fr; }
      .bottom-strip { grid-template-columns: 1fr; }
      .bottom-list { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <div class="shell">
    <!-- TOP BAR -->
    <header class="topbar">
      <div class="brand">
        <div class="brand-icon">🌊</div>
        <div>
          <div class="brand-text-main">ReachX Workforce Cloud</div>
          <div class="brand-text-sub">Mauritius blue-collar hiring · outreach · housing</div>
        </div>
      </div>
      <div class="top-tags">
        <div class="chip accent"><strong>Demo app</strong> · Not connected to live data</div>
        <div class="chip"><strong>Mauritius</strong> · Retail · Hospitality · Construction</div>
        <div class="chip"><strong>Operator:</strong> Omran</div>
      </div>
    </header>

    <!-- HERO ROW -->
    <section class="hero">
      <!-- LEFT: VALUE & FLOW -->
      <div class="hero-left">
        <div class="hero-left-inner">
          <div class="hero-title">One cockpit for employers, agents & staff.</div>
          <div class="hero-subline">
            ReachX keeps every vacancy, candidate and bed in sync — so Mauritian employers stay fully staffed while you work from one screen.
          </div>

          <div class="hero-metrics">
            <div class="hero-metric">
              <div class="hero-metric-label">Time saved</div>
              <div class="hero-metric-main">
                <div class="hero-metric-value">10+</div>
                <div style="font-size:10px;color:var(--text-muted);">hours / week</div>
              </div>
              <div class="hero-metric-foot">No more manual Excel + scattered WhatsApp follow-ups.</div>
            </div>
            <div class="hero-metric">
              <div class="hero-metric-label">Roles filled faster</div>
              <div class="hero-metric-main">
                <div class="hero-metric-value">30%</div>
                <div style="font-size:10px;color:var(--text-muted);">average</div>
              </div>
              <div class="hero-metric-foot">Prioritise HOT revenue roles automatically.</div>
            </div>
            <div class="hero-metric">
              <div class="hero-metric-label">Dorm beds sold</div>
              <div class="hero-metric-main">
                <div class="hero-metric-value">95%</div>
                <div style="font-size:10px;color:var(--text-muted);">occupancy</div>
              </div>
              <div class="hero-metric-foot">Link every hire to a real bed in Mauritius.</div>
            </div>
          </div>

          <div class="hero-flow">
            <div style="font-size:10px;margin-bottom:4px;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.12em;">
              DAILY FLOW · EL5
            </div>
            <div class="flow-row">
              <div class="flow-step"><span>🏢</span>Employers & roles</div>
              <div class="flow-arrow">➜</div>
              <div class="flow-step"><span>🧠</span>ReachX brain</div>
              <div class="flow-arrow">➜</div>
              <div class="flow-step"><span>📧</span>Emails / calls / WhatsApp</div>
              <div class="flow-arrow">➜</div>
              <div class="flow-step"><span>🧑‍🔧</span>Candidates & beds</div>
              <div class="flow-arrow">➜</div>
              <div class="flow-step"><span>💰</span>Filled shifts & revenue</div>
            </div>
            <div class="hero-footnote">
              You open this board, hit “run outreach”, update a few statuses — ReachX tracks the rest.
            </div>
          </div>
        </div>
      </div>

      <!-- RIGHT: DASHBOARD PREVIEW -->
      <div class="hero-right">
        <div class="dash-frame">
          <div class="dash-top">
            <div class="dash-title-group">
              <div class="dash-title">Today in ReachX · Mauritius</div>
              <div class="dash-sub">Quick view of employers, roles, staff & housing.</div>
            </div>
            <div class="dash-badges">
              <div class="dash-badge green">System: OK</div>
              <div class="dash-badge">9 active roles</div>
            </div>
          </div>

          <div class="dash-tabs">
            <button class="dash-tab active" data-target="tab-roles"><span>🎯</span> Roles</button>
            <button class="dash-tab" data-target="tab-employers"><span>🏢</span> Employers</button>
            <button class="dash-tab" data-target="tab-staff"><span>🧑‍🔧</span> Candidates & agents</button>
            <button class="dash-tab" data-target="tab-dorms"><span>🏠</span> Dormitories</button>
            <button class="dash-tab" data-target="tab-activity"><span>📞</span> Activity</button>
          </div>

          <!-- Tabs content -->
          <div class="dash-main">
            <!-- LEFT panel: swaps with tabs -->
            <div id="tab-roles" class="dash-card dash-view active">
              <div class="dash-card-header">
                <div class="dash-card-title">Open roles (Mauritius)</div>
                <div class="dash-card-sub">Sorted by “money on the table”.</div>
              </div>
              <table class="dash-table">
                <thead>
                  <tr>
                    <th>Role</th>
                    <th>Employer</th>
                    <th>Headcount</th>
                    <th>Urgency</th>
                    <th>Next action</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="label-main">Store Cashier</td>
                    <td>Intermart</td>
                    <td>6</td>
                    <td><span class="score-chip score-hot">HOT</span></td>
                    <td><span class="status-pill">Send WhatsApp pack</span></td>
                  </tr>
                  <tr>
                    <td class="label-main">Shelf Filler</td>
                    <td>Dreamprice</td>
                    <td>8</td>
                    <td><span class="score-chip score-warm">WARM</span></td>
                    <td><span class="status-pill">Email follow-up</span></td>
                  </tr>
                  <tr>
                    <td class="label-main">Housekeeping</td>
                    <td>BlueLife Hotels</td>
                    <td>10</td>
                    <td><span class="score-chip score-hot">HOT</span></td>
                    <td><span class="status-pill">Lock interviews</span></td>
                  </tr>
                  <tr>
                    <td class="label-main">Site Worker</td>
                    <td>XYZ Construction</td>
                    <td>14</td>
                    <td><span class="score-chip score-cold">COLD</span></td>
                    <td><span class="status-pill idle">First outreach</span></td>
                  </tr>
                </tbody>
              </table>
              <div class="mini-note">
                In the live app, clicking a row opens employer, candidates, dorm beds and contracts on one screen.
              </div>
            </div>

            <div id="tab-employers" class="dash-card dash-view">
              <div class="dash-card-header">
                <div class="dash-card-title">Employer health</div>
                <div class="dash-card-sub">Retail · hospitality · construction.</div>
              </div>
              <table class="dash-table">
                <thead>
                  <tr>
                    <th>Employer</th>
                    <th>Sector</th>
                    <th>Open roles</th>
                    <th>Last touch</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="label-main">Intermart</td>
                    <td>Supermarket</td>
                    <td>12</td>
                    <td>Today · WhatsApp</td>
                    <td><span class="status-pill">In discussion</span></td>
                  </tr>
                  <tr>
                    <td class="label-main">Dreamprice</td>
                    <td>Retail</td>
                    <td>8</td>
                    <td>Yesterday · Email</td>
                    <td><span class="status-pill idle">Waiting reply</span></td>
                  </tr>
                  <tr>
                    <td class="label-main">BlueLife Limited</td>
                    <td>Hospitality</td>
                    <td>10</td>
                    <td>This week · Call</td>
                    <td><span class="status-pill">Positive</span></td>
                  </tr>
                  <tr>
                    <td class="label-main">XYZ Construction</td>
                    <td>Construction</td>
                    <td>14</td>
                    <td>New</td>
                    <td><span class="status-pill idle">Prospect</span></td>
                  </tr>
                </tbody>
              </table>
              <div class="mini-note">
                “Red” employers float to the top so you never miss a Mauritian client.
              </div>
            </div>

            <div id="tab-staff" class="dash-card dash-view">
              <div class="dash-card-header">
                <div class="dash-card-title">Candidates & agents</div>
                <div class="dash-card-sub">Linked to roles and dorms.</div>
              </div>
              <table class="dash-table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>From</th>
                    <th>Agent</th>
                    <th>Target role</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="label-main">Rahul Kumar</td>
                    <td>India</td>
                    <td>Chennai partner</td>
                    <td>Store Cashier</td>
                    <td><span class="status-pill">Shortlisted</span></td>
                  </tr>
                  <tr>
                    <td class="label-main">Hasan Ali</td>
                    <td>Bangladesh</td>
                    <td>Dhaka partner</td>
                    <td>Shelf Filler</td>
                    <td><span class="status-pill">Interview booked</span></td>
                  </tr>
                  <tr>
                    <td class="label-main">Sanjay Thapa</td>
                    <td>Nepal</td>
                    <td>Kathmandu partner</td>
                    <td>Housekeeping</td>
                    <td><span class="status-pill idle">Docs pending</span></td>
                  </tr>
                </tbody>
              </table>
              <div class="mini-note">
                Every candidate connects to employer contract + dormitory contract automatically.
              </div>
            </div>

            <div id="tab-dorms" class="dash-card dash-view">
              <div class="dash-card-header">
                <div class="dash-card-title">Dorms & beds</div>
                <div class="dash-card-sub">Where your people sleep in Mauritius.</div>
              </div>
              <table class="dash-table">
                <thead>
                  <tr>
                    <th>Dorm</th>
                    <th>Location</th>
                    <th>Capacity</th>
                    <th>Occupied</th>
                    <th>Free</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="label-main">Dorm A</td>
                    <td>Plaine Magnien</td>
                    <td>40</td>
                    <td>28</td>
                    <td>12</td>
                  </tr>
                  <tr>
                    <td class="label-main">Dorm B</td>
                    <td>Mahebourg</td>
                    <td>30</td>
                    <td>22</td>
                    <td>8</td>
                  </tr>
                  <tr>
                    <td class="label-main">Dorm C</td>
                    <td>Port Louis</td>
                    <td>25</td>
                    <td>3</td>
                    <td>22</td>
                  </tr>
                </tbody>
              </table>
              <div class="mini-note">
                The system flashes a warning if hires exceed beds for the week.
              </div>
            </div>

            <div id="tab-activity" class="dash-card dash-view">
              <div class="dash-card-header">
                <div class="dash-card-title">Today’s activity</div>
                <div class="dash-card-sub">Emails · calls · WhatsApp in one feed.</div>
              </div>
              <table class="dash-table">
                <thead>
                  <tr>
                    <th>Time</th>
                    <th>Channel</th>
                    <th>Who</th>
                    <th>Summary</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td>09:10</td>
                    <td>WhatsApp</td>
                    <td>Intermart HR</td>
                    <td>Sent shortlist + dorm options.</td>
                  </tr>
                  <tr>
                    <td>09:45</td>
                    <td>Email</td>
                    <td>Dreamprice Ops</td>
                    <td>Follow-up with updated rates.</td>
                  </tr>
                  <tr>
                    <td>10:30</td>
                    <td>Call</td>
                    <td>BlueLife HR</td>
                    <td>Confirmed interviews for 6 staff.</td>
                  </tr>
                  <tr>
                    <td>11:15</td>
                    <td>Note</td>
                    <td>Internal</td>
                    <td>Dorm B nearly full; route new to Dorm C.</td>
                  </tr>
                </tbody>
              </table>
              <div class="mini-note">
                In the live system, these rows are written automatically when your scripts run.
              </div>
            </div>

            <!-- RIGHT panel: Money & time chart -->
            <div class="dash-card">
              <div class="dash-card-header">
                <div class="dash-card-title">Impact for a Recruiter in Mauritius</div>
                <div class="dash-card-sub">Very rough monthly picture.</div>
              </div>
              <div class="bar-wrap">
                <div class="bar">
                  <div class="bar-inner" style="height:72%;"></div>
                  <div class="bar-label">Rs 300k</div>
                  <div class="bar-caption">Revenue with ReachX</div>
                </div>
                <div class="bar">
                  <div class="bar-inner alt" style="height:45%;"></div>
                  <div class="bar-label">Rs 190k</div>
                  <div class="bar-caption">Manual spreadsheets</div>
                </div>
              </div>
              <div class="mini-note">
                Concept: by filling roles faster and keeping beds full, the same team can push significantly more turnover through Mauritius each month.
              </div>
              <div class="mini-note" style="margin-top:5px;">
                You can adjust the real numbers per employer and contract once this is live.
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- BOTTOM STRIP: HOW IT RUNS DAY TO DAY -->
    <section class="bottom-strip">
      <div class="bottom-card">
        <div class="bottom-title">How operators in Mauritius would actually use it</div>
        <div class="bottom-list">
          <div class="bottom-item">
            <div class="bottom-icon">1</div>
            <div>
              <div class="bottom-text-main">Morning: check the board</div>
              <div class="bottom-text-sub">See HOT roles, free beds and which employers might churn.</div>
            </div>
          </div>
          <div class="bottom-item">
            <div class="bottom-icon">2</div>
            <div>
              <div class="bottom-text-main">Run outreach in one click</div>
              <div class="bottom-text-sub">System generates email, WhatsApp and call lists automatically.</div>
            </div>
          </div>
          <div class="bottom-item">
            <div class="bottom-icon">3</div>
            <div>
              <div class="bottom-text-main">Match candidates to roles</div>
              <div class="bottom-text-sub">Each candidate is tied to an employer, agent and dormitory.</div>
            </div>
          </div>
          <div class="bottom-item">
            <div class="bottom-icon">4</div>
            <div>
              <div class="bottom-text-main">Contracts & compliance</div>
              <div class="bottom-text-sub">Employer, employee and dorm contracts are all visible from the same profile.</div>
            </div>
          </div>
        </div>
      </div>

      <div class="bottom-card">
        <div class="bottom-right-rows">
          <div>
            <div class="bottom-title">Why invest in ReachX (Mauritius-first)</div>
            <div class="bottom-tag-row">
              <div class="small-pill"><strong>⏱️ Less admin:</strong> one cockpit, not 10 spreadsheets.</div>
              <div class="small-pill"><strong>💰 More revenue:</strong> fill roles and beds faster.</div>
              <div class="small-pill"><strong>🧑‍💼 Multi-employer:</strong> Intermart, Dreamprice, BlueLife, XYZ & more.</div>
              <div class="small-pill"><strong>🌍 Cross-border:</strong> agents in India, Bangladesh, Nepal, UAE.</div>
              <div class="small-pill"><strong>📞 All comms:</strong> emails, calls, WhatsApp linked to each record.</div>
            </div>
          </div>
          <div>
            <div class="bottom-title">Simple structure behind the pretty screen</div>
            <div class="bottom-tag-row">
              <div class="small-pill">Staff</div>
              <div class="small-pill">Employers</div>
              <div class="small-pill">Agents (countries)</div>
              <div class="small-pill">Candidates</div>
              <div class="small-pill">Dormitories</div>
              <div class="small-pill">Emails · Calls · WhatsApp</div>
              <div class="small-pill">Contracts (employer / employee / dorm)</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>

  <script>
    (function () {
      var tabs = document.querySelectorAll(".dash-tab");
      var views = document.querySelectorAll(".dash-view");

      function show(id) {
        views.forEach(function (v) {
          if (v.id === id) v.classList.add("active");
          else v.classList.remove("active");
        });
      }

      tabs.forEach(function (tab) {
        tab.addEventListener("click", function () {
          var target = tab.getAttribute("data-target");
          if (!target) return;
          tabs.forEach(function (t) { t.classList.remove("active"); });
          tab.classList.add("active");
          show(target);
        });
      });
    })();
  </script>
</body>
</html>
'@

Set-Content -Path $htmlPath -Value $html -Encoding UTF8

Write-Host ""
Write-Host "ReachX demo UI generated at:" -ForegroundColor Green
Write-Host "  $htmlPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Opening in your default browser..." -ForegroundColor Yellow

Start-Process $htmlPath
