import asyncio
import sys
import argparse
import json
import uuid
import os
from datetime import datetime, timezone
from pathlib import Path
from collections import deque
from urllib.parse import urlparse

from playwright.async_api import async_playwright

# -----------------------------
# CONFIG / DEFAULTS
# -----------------------------
DEFAULT_BASE_URL = "http://localhost:8001"
DEFAULT_MAX_PAGES = 50

SKIP_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".css", ".js", ".ico", ".map", ".woff", ".woff2", ".ttf"}
SKIP_SCHEMES = ("mailto:", "tel:")

# FIX: Windows Console Encoding (Use UTF-8 for Safe Text)
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

# -----------------------------
# STATE (per run)
# -----------------------------
visited = set()
broken_links = []
console_errors = []
console_warnings = []
network_failures = []
journey_results = []

# -----------------------------
# PATHS (portable)
# -----------------------------
def resolve_titan_root() -> Path:
    env_root = os.environ.get("TITAN_ROOT")
    if env_root:
        return Path(env_root).resolve()
    return Path(__file__).resolve().parents[2]

def get_report_dir(titan_root: Path) -> Path:
    return titan_root / "apps" / "inspector" / "reports"

# -----------------------------
# URL HELPERS
# -----------------------------
def parse_url(url: str):
    return urlparse(url)

def hostname(url: str) -> str:
    try:
        return (parse_url(url).hostname or "").lower()
    except Exception:
        return ""

def normalize_url(url: str) -> str:
    u = url.split("#")[0].rstrip("/")
    return u

def is_same_origin(url: str, base_url: str) -> bool:
    bu = parse_url(base_url)
    uu = parse_url(url)
    b_host = (bu.hostname or "").lower()
    u_host = (uu.hostname or "").lower()
    if b_host != u_host:
        return False
    if bu.port is not None:
        return uu.port == bu.port
    return True

def should_skip_url(url: str) -> bool:
    if not url:
        return True
    url_l = url.lower()
    if url_l.startswith(SKIP_SCHEMES):
        return True
    try:
        pu = parse_url(url)
        path = (pu.path or "").lower()
        for ext in SKIP_EXTS:
            if path.endswith(ext):
                return True
        if "logout" in path:
            return True
    except Exception:
        return True
    return False

# -----------------------------
# CRAWL (QUEUE-BASED)
# -----------------------------
async def crawl(page, start_url: str, base_url: str, max_pages: int):
    start_url = normalize_url(start_url)
    q = deque([start_url])

    while q and len(visited) < max_pages:
        url = normalize_url(q.popleft())
        if url in visited: continue
        if not is_same_origin(url, base_url): continue
        if should_skip_url(url): continue

        print(f"[CRAWL] Crawling: {url}")
        visited.add(url)

        try:
            response = await page.goto(url, wait_until="domcontentloaded", timeout=10000)
            await page.wait_for_timeout(300)

            if not response:
                broken_links.append({"url": url, "status": 0, "reason": "No response object"})
                print(f"[FAIL] Broken: {url} (no response)")
                continue

            if response.status >= 400:
                broken_links.append({"url": url, "status": response.status, "reason": "HTTP Error"})
                print(f"[FAIL] Broken: {url} ({response.status})")
                continue

            hrefs = await page.eval_on_selector_all("a[href]", "els => els.map(e => e.href)")
            for h in hrefs:
                if not h: continue
                h = normalize_url(h)
                if h in visited: continue
                if not is_same_origin(h, base_url): continue
                if should_skip_url(h): continue
                q.append(h)

        except Exception as e:
            broken_links.append({"url": url, "status": 0, "reason": str(e)})
            print(f"[FAIL] Failed: {url} - {str(e)}")

# -----------------------------
# JOURNEY: GRANTS (INTAKE -> GENERATE)
# -----------------------------
async def run_journey_grants(page, base_url: str):
    print("[JOURNEY] Starting Journey: Grants Flow")
    try:
        await page.goto(f"{base_url}/portal/intake", wait_until="domcontentloaded", timeout=15000)
        await page.wait_for_timeout(250)

        # Step 1
        await page.fill("#fullName", "Inspector Bot")
        await page.fill("#emailAddr", "inspector@example.com")
        await page.fill("#sectorInput", "Export") # Trigger Export Scheme Logic
        await page.fill("#companyAge", "3")
        await page.click("#nextBtn", force=True)

        # Step 2
        await page.wait_for_timeout(300)
        await page.click("input[name='goal'][value='funding']", force=True)
        await page.click("#nextBtn", force=True)

        # Step 3
        await page.wait_for_timeout(300)
        await page.fill("#ideaRaw", "Automated QA Project")
        await page.fill("#beneficiaries", "QA Bot")
        await page.fill("#budget", "50000")
        await page.click("#nextBtn", force=True)

        # Step 4
        await page.wait_for_timeout(300)
        await page.click("input[name='finance'][value='yes']", force=True)
        await page.click("input[name='entity'][value='yes']", force=True)
        await page.click("#nextBtn", force=True)

        # Step 5
        await page.wait_for_timeout(300)
        await page.click("#consent", force=True)
        # Try standard click first to trigger JS listeners properly
        await page.click("#submitBtn")

        # Let the UI settle / simulate
        print("[WAIT] Waiting for simulation to complete...")
        # Wait for overlay to appear (extended timeout)
        await page.wait_for_selector("#simulationOverlay", state="visible", timeout=30000)
        print(f"[DEBUG] Overlay visible: {await page.is_visible('#simulationOverlay')}")

        # Wait for the download button to actually become visible (end of simulation)
        await page.wait_for_selector("#downloadBtn", state="visible", timeout=30000)

        def is_generate_call(resp):
            try:
                return (
                    "/api/grants/tinns/generate" in resp.url
                    and resp.request.method == "POST"
                )
            except Exception:
                return False

        # Wait for generate response
        async with page.expect_response(is_generate_call, timeout=30000) as response_info:
            await page.click("#downloadBtn", force=True)

        resp = await response_info.value
        if resp.status != 200:
            body = await resp.text()
            raise Exception(f"Generate failed: HTTP {resp.status} | {body[:200]}")

        ct = (resp.headers.get("content-type") or "").lower()
        if "pdf" not in ct:
            console_warnings.append(f"Generate response content-type not PDF: {ct}")

        journey_results.append({"name": "Grants Flow", "status": "PASS"})
        print("[PASS] Grants Flow Passed")

    except Exception as e:
        journey_results.append({"name": "Grants Flow", "status": "FAIL", "error": str(e)})
        print(f"[FAIL] Grants Flow Failed: {str(e)}")

# -----------------------------
# REPORTING
# -----------------------------
def now_iso() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat()

def write_reports(report_dir: Path, report: dict, is_healthy: bool):
    latest = report_dir / "latest"
    latest.mkdir(parents=True, exist_ok=True)
    
    report_file = latest / "audit.json"
    print(f"[DEBUG] Writing to: {report_file}")
    report_file.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")

    status_emoji = "[PASS]" if is_healthy else "[FAIL]"
    md = []
    md.append("# TITAN Inspector Report")
    md.append(f"Date: {datetime.now().isoformat()}")
    md.append("")
    md.append(f"# Status: {status_emoji}")
    md.append("")

    if report["broken_links"]:
        md.append("## [X] Broken Links")
        md.extend([f"- {l['url']}: {l['reason']} ({l.get('status', 0)})" for l in report["broken_links"]])
        md.append("")

    if report["console_errors"]:
        md.append("## [X] Console Errors")
        md.extend([f"- {e}" for e in report["console_errors"]])
        md.append("")

    if report["journeys"]:
        md.append("## [JOURNEY] Journeys")
        md.extend([f"- {j['name']}: {j['status']} {j.get('error','')}".rstrip() for j in report["journeys"]])
        md.append("")

    if report["network_failures"]:
        md.append("## [WARN] Network Failures")
        md.extend([f"- {n}" for n in report["network_failures"]])
        md.append("")

    if report["console_warnings"]:
        md.append("## [INFO] Console Warnings")
        md.extend([f"- {w}" for w in report["console_warnings"]])
        md.append("")

    (latest / "audit.md").write_text("\n".join(md).strip() + "\n", encoding="utf-8")

    (latest / "audit.md").write_text("\n".join(md).strip() + "\n", encoding="utf-8")

# -----------------------------
# HELPERS
# -----------------------------
def _human_summary(level, cerrs, fails, broken):
    if level == "critical":
        return f"Critical issues detected: {cerrs} console errors and {fails} network failures. Immediate action required."
    if level == "warn":
        return f"Warnings detected: {broken} broken links. Site mostly works but needs cleanup."
    return "All checks passed. No broken links, console errors, or network failures detected."

def _next_steps(level):
    if level == "critical":
        return ["Trigger Doctor with this report", "Block deployment until fixed", "Re-run Inspector after patch"]
    if level == "warn":
        return ["Trigger Doctor to patch link map", "Re-run Inspector"]
    return ["Keep monitoring"]

# -----------------------------
# MAIN
# -----------------------------
async def main():
    global STRICT_MODE, DEFAULT_MAX_PAGES

    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default=DEFAULT_BASE_URL, help="Start URL for crawl (or base URL)")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL, help="Base URL used for same-origin checks")
    parser.add_argument("--mode", default="crawl", choices=["crawl", "journey", "both"])
    parser.add_argument("--strict", action="store_true", help="Strict mode: fail on any console error and broken links")
    parser.add_argument("--strict-warnings", action="store_true", help="If set, warnings also fail the run")
    parser.add_argument("--max-pages", type=int, default=DEFAULT_MAX_PAGES)
    args = parser.parse_args()

    strict_mode = args.strict
    strict_warnings = args.strict_warnings
    max_pages = args.max_pages
    base_url = args.base_url.rstrip("/")

    titan_root = resolve_titan_root()
    report_dir = get_report_dir(titan_root)

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            user_agent="TITAN-Inspector/1.0",
            extra_http_headers={"X-Titan-Inspector": "1"},
        )
        page = await context.new_page()

        def console_handler(msg):
            try:
                if not msg.text: return
                text = msg.text.lower()
                if "fonts.gstatic" in text: return
                if "blocked by cors" in text or ("cors" in text and "font" in text): return
                # FILTER: Redundant network errors (captured by request_failed)
                if "failed to load resource" in text: return
                
                if msg.type == "error":
                    console_errors.append(msg.text)
                elif msg.type == "warning":
                    console_warnings.append(msg.text)
            except Exception:
                pass

        def request_failed(req):
            try:
                if not req.url: return
                if "fonts.gstatic" in req.url.lower(): return
                failure = req.failure
                network_failures.append(f"{req.method} {req.url} - {failure}")
            except Exception:
                network_failures.append(f"{req.method} {req.url if req else 'UNKNOWN'} - requestfailed")

        page.on("console", console_handler)
        page.on("requestfailed", request_failed)

        try:
            if args.mode == "crawl":
                await crawl(page, args.url, base_url, max_pages)
            elif args.mode == "journey":
                await run_journey_grants(page, base_url)
            elif args.mode == "both":
                await run_journey_grants(page, base_url)
                await crawl(page, args.url, base_url, max_pages)

        except Exception as e:
            print(f"[FAIL] CRITICAL INSPECTOR CRASH: {e}")
            broken_links.append({"url": "INSPECTOR_CORE", "status": 500, "reason": str(e)})

        finally:
            await browser.close()

            report = {
                "timestamp": now_iso(),
                "status": "UNKNOWN",
                "base_url": base_url,
                "start_url": args.url,
                "mode": args.mode,
                "max_pages": max_pages,
                "visited_count": len(visited),
                "broken_links": broken_links,
                "console_errors": console_errors,
                "console_warnings": console_warnings,
                "network_failures": network_failures,
                "journeys": journey_results,
            }

            is_healthy = (
                not broken_links
                and not console_errors
                and (not journey_results or all(j.get("status") == "PASS" for j in journey_results))
                and (not strict_warnings or not console_warnings)
            )

            # Map to Status/Severity
            status = "PASS" if is_healthy else "FAIL"
            severity = "critical" if (console_errors or network_failures) else ("warn" if broken_links else "info")
            if not is_healthy and severity == "info": severity = "warn" # Fallback if journey failed but no other errors

            # Canonical Envelope
            report = {
                "ok": is_healthy,
                "request_id": str(uuid.uuid4()),
                "ts": now_iso(),
                "agent": "Inspector",
                "severity": severity,
                "human_summary": _human_summary(severity, len(console_errors), len(network_failures), len(broken_links)),
                "findings": {
                    "broken_links": broken_links,
                    "console_errors": console_errors,
                    "network_failures": network_failures,
                    "journeys": journey_results,
                },
                "metrics": {
                    "pages_visited": len(visited),
                    "broken_links_count": len(broken_links),
                    "console_errors_count": len(console_errors),
                    "network_failures_count": len(network_failures),
                    "journeys_count": len(journey_results)
                },
                "next_steps": _next_steps(severity),
                # Legacy Back-compat
                "status": status,
                "timestamp": now_iso(),
                "journeys": journey_results,
                "console_errors": console_errors,
                "broken_links": broken_links,
                "network_failures": network_failures,
                "console_warnings": console_warnings
            }

            write_reports(report_dir, report, is_healthy)

            status_emoji = "[PASS]" if is_healthy else "[FAIL]"
            print(f"Report Generated: {status_emoji}")
            sys.exit(0 if is_healthy else 1)

if __name__ == "__main__":
    asyncio.run(main())
