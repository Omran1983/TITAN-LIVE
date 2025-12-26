// bulk-payslips.mjs (final, timeout-proof)
import fs from "fs";
import path from "path";
import puppeteer from "puppeteer";
import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_KEY  = process.env.SUPABASE_SERVICE_KEY;

function die(msg) { console.error(msg); process.exit(1); }
if (!SUPABASE_URL) die("Missing SUPABASE_URL env var.");
if (!SERVICE_KEY)  die("Missing SUPABASE_SERVICE_KEY env var (service_role key).");

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

const fmt  = v => new Intl.NumberFormat('en-MU',{style:'currency',currency:'MUR'}).format(Number(v||0));
const toMU = d => new Date(d).toLocaleDateString('en-MU',{day:'2-digit',month:'short',year:'numeric'});

// Self-contained HTML (no external fonts → faster, no network waits)
const tmpl = (r) => {
  const earningsTotal = Number(r.gross_total ?? (r.gross_basic + r.gross_overtime + r.allowances));
  const dedTotal      = Number(r.employee_deductions_total ?? (r.csg_emp + r.nsf_emp + r.paye + r.deductions));
  const employerTotal = Number(r.employer_contrib_total ?? (r.csg_er + r.nsf_er + r.hrdc_levy + r.prgf_er));
  return `<!doctype html><html><head>
<meta charset="utf-8"/>
<title>Payslip ${r.code}</title>
<style>
:root{--ink:#0f172a;--muted:#6b7280;--line:#e5e7eb;--ok:#16a34a;}
body{margin:0;font-family:system-ui,Segoe UI,Roboto,Arial;color:var(--ink);}
.sheet{width:210mm;min-height:297mm;padding:12mm 12mm 14mm 12mm;}
.brand{display:flex;justify-content:space-between;align-items:center;}
.muted{color:var(--muted);font-size:12px}
h1{margin:0;font-size:18px} h3{margin:14px 0 6px 0;font-size:14px}
hr{border:0;border-top:1px solid var(--line);margin:10px 0}
.kv{display:grid;grid-template-columns:160px 1fr;gap:6px 12px;margin:6px 0 0 0}
table{width:100%;border-collapse:collapse}
th,td{padding:8px;border-bottom:1px solid var(--line);text-align:left}
th{background:#f9fafb}
.t-right{text-align:right}
.totals{display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;margin-top:12px}
.card{border:1px solid var(--line);border-radius:10px;padding:10px}
.total{font-size:20px;font-weight:700}
.net{color:var(--ok)}
.footer{display:flex;justify-content:space-between;margin-top:16px;font-size:12px;color:var(--muted)}
.badge{display:inline-block;padding:4px 8px;border-radius:999px;font-size:12px;border:1px solid var(--line)}
</style>
</head><body>
<div class="sheet">
  <div class="brand">
    <div>
      <h1>A-One Global Resourcing Ltd</h1>
      <div class="muted">Mauritius • BRN C22185206 • TAN 28006142</div>
    </div>
    <div style="text-align:right">
      <div style="font-weight:700;font-size:18px">PAYSLIP</div>
      <div class="muted">${toMU(r.period_start)} — ${toMU(r.period_end)}</div>
    </div>
  </div>
  <hr/>
  <div class="kv">
    <b>Employee</b><span>${r.first_name} ${r.last_name}</span>
    <b>Employee Code</b><span>${r.code}</span>
    <b>National ID</b><span>${r.national_id ?? '—'}</span>
    <b>Bank</b><span>${r.bank_name ?? '—'} ${r.bank_iban ? '• '+r.bank_iban : ''}</span>
  </div>
  <div style="margin:8px 0">${(r.anomalies_in_period||0) > 0 ? `<span class="badge">Anomalies: ${r.anomalies_in_period}</span>` : `<span class="badge">No anomalies</span>`}</div>
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
    <div>
      <h3>Earnings</h3>
      <table><thead><tr><th>Component</th><th class="t-right">Amount (MUR)</th></tr></thead><tbody>
        <tr><td>Basic Salary</td><td class="t-right">${fmt(r.gross_basic)}</td></tr>
        <tr><td>Overtime</td><td class="t-right">${fmt(r.gross_overtime)}</td></tr>
        ${Number(r.allowances||0)>0 ? `<tr><td>Allowances</td><td class="t-right">${fmt(r.allowances)}</td></tr>`:''}
      </tbody><tfoot><tr><th>Total</th><th class="t-right">${fmt(earningsTotal)}</th></tr></tfoot></table>
    </div>
    <div>
      <h3>Employee Deductions</h3>
      <table><thead><tr><th>Component</th><th class="t-right">Amount (MUR)</th></tr></thead><tbody>
        ${Number(r.paye||0)>0 ? `<tr><td>PAYE</td><td class="t-right">${fmt(r.paye)}</td></tr>`:''}
        ${Number(r.csg_emp||0)>0 ? `<tr><td>CSG (Employee)</td><td class="t-right">${fmt(r.csg_emp)}</td></tr>`:''}
        ${Number(r.nsf_emp||0)>0 ? `<tr><td>NSF (Employee)</td><td class="t-right">${fmt(r.nsf_emp)}</td></tr>`:''}
        ${Number(r.deductions||0)>0 ? `<tr><td>Other Deductions</td><td class="t-right">${fmt(r.deductions)}</td></tr>`:''}
      </tbody><tfoot><tr><th>Total</th><th class="t-right">${fmt(dedTotal)}</th></tr></tfoot></table>
    </div>
  </div>
  <div style="margin-top:12px">
    <h3>Employer Contributions</h3>
    <table><thead><tr><th>Component</th><th class="t-right">Amount (MUR)</th></tr></thead><tbody>
      ${Number(r.csg_er||0)>0 ? `<tr><td>CSG (Employer)</td><td class="t-right">${fmt(r.csg_er)}</td></tr>`:''}
      ${Number(r.nsf_er||0)>0 ? `<tr><td>NSF (Employer)</td><td class="t-right">${fmt(r.nsf_er)}</td></tr>`:''}
      ${Number(r.hrdc_levy||0)>0 ? `<tr><td>HRDC Levy</td><td class="t-right">${fmt(r.hrdc_levy)}</td></tr>`:''}
      ${Number(r.prgf_er||0)>0 ? `<tr><td>PRGF</td><td class="t-right">${fmt(r.prgf_er)}</td></tr>`:''}
    </tbody><tfoot><tr><th>Total</th><th class="t-right">${fmt(employerTotal)}</th></tr></tfoot></table>
  </div>
  <div class="totals">
    <div class="card"><div>Gross Pay</div><div class="total">${fmt(earningsTotal)}</div></div>
    <div class="card"><div>Deductions</div><div class="total">${fmt(dedTotal)}</div></div>
    <div class="card"><div>Net Pay</div><div class="total net">${fmt(r.net_pay)}</div></div>
  </div>
  <div class="muted" style="margin-top:10px">
    Hours: base ${Number(r.base_hours||0)} • OT1.5 ${Number(r.ot_15_hours||0)} • Hol2x ${Number(r.hol_2x_hours||0)} • Hol3x ${Number(r.hol_3x_hours||0)}
  </div>
  <div class="footer">
    <div>Generated by AOGRL Payroll — valid without signature</div>
    <div>Run ${r.run_id}</div>
  </div>
</div>
</body></html>`;
};

async function main() {
  // Validate key against /auth/v1/settings (clean error if wrong)
  const res = await fetch(`${SUPABASE_URL}/auth/v1/settings`, { headers: { apikey: SERVICE_KEY } });
  if (!res.ok) die(`Invalid API key for ${SUPABASE_URL}. Re-copy the service_role key from Studio → Settings → API.`);

  // Pull latest run’s payslip rows
  const { data: rows, error } = await supabase
    .from("v_payslip_latest")
    .select("*")
    .order("code", { ascending: true });

  if (error) die(`Failed to read v_payslip_latest: ${error.message || error}`);
  if (!rows || rows.length === 0) { console.log("No rows in v_payslip_latest."); return; }

  const payMonth = new Date(rows[0].period_start).toISOString().slice(0,7); // YYYY-MM
  const outDir = path.join("out", payMonth);
  fs.mkdirSync(outDir, { recursive: true });
  console.log(`Generating ${rows.length} payslips into ${outDir} …`);

  const browser = await puppeteer.launch({ headless: "new", args: ["--no-sandbox","--disable-setuid-sandbox"] });
  const NAV_OPTS = { waitUntil: "domcontentloaded", timeout: 0 };

  for (const r of rows) {
    const page = await browser.newPage();
    page.setDefaultNavigationTimeout(0);
    page.setDefaultTimeout(0);

    const html = tmpl(r);
    await page.setContent(html, NAV_OPTS);
    await page.emulateMediaType("screen");

    const safeName = `${r.code} - ${r.first_name ?? ""} ${r.last_name ?? ""}`.trim().replace(/[\\/:*?"<>|]/g,'_');
    const filePath = path.join(outDir, `${safeName}.pdf`);

    await page.pdf({ path: filePath, format: "A4", printBackground: true,
      margin: { top:"12mm", bottom:"12mm", left:"12mm", right:"12mm" } });

    console.log("✓", filePath);
    await page.close();
  }

  await browser.close();
  console.log("Done.");
}

main().catch(e => { console.error("Fatal:", e?.message || e); process.exit(1); });
