from __future__ import annotations

import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any

from fastapi import FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.responses import HTMLResponse, JSONResponse, FileResponse
from fastapi.templating import Jinja2Templates

# Reload trigger: 2025-12-23 22:04
# --- PATHS / ROOTS ---
BRIDGE_DIR = Path(__file__).parent
TITAN_ROOT = BRIDGE_DIR.parent
APPS_DIR = TITAN_ROOT / "apps"
PORTAL_DIR = APPS_DIR / "portal"
TEMPLATES_DIR = PORTAL_DIR / "templates"
CATALOG_PATH = PORTAL_DIR / "catalog.json"

# IO: prefer env override for portability (Laptop2, server, etc.)
# VERCEL FIX: Detect if we are in a read-only environment (Lambda)
if os.environ.get("VERCEL") or os.name != "nt":
     # Linux/Vercel (Writeable only in /tmp)
    IO_ROOT = Path("/tmp/titan_io")
else:
    # Windows Dev
    IO_ROOT = Path(os.environ.get("TITAN_IO_ROOT", r"F:\AION-ZERO\TITAN\io"))

INBOX = IO_ROOT / "inbox"
OUTBOX = IO_ROOT / "outbox"

# Don't crash if mkdir fails (e.g. unexpected perms), but try.
try:
    INBOX.mkdir(parents=True, exist_ok=True)
    OUTBOX.mkdir(parents=True, exist_ok=True)
    TEMPLATES_DIR.mkdir(parents=True, exist_ok=True)
except Exception as e:
    print(f"[WARN] IO Dir creation failed: {e}")

# --- TITAN MODULE IMPORTS (Safe Loading) ---
try:
    sys.path.append(str(APPS_DIR / "grant_writer"))
    from tinns_generator import TinnsGenerator
except Exception as e:
    print(f"[WARN] Failed to load TinnsGenerator: {e}")
    TinnsGenerator = None

try:
    sys.path.append(str(APPS_DIR / "audit"))
    from audit_engine import ContractAuditor
except Exception as e:
    print(f"[WARN] Failed to load ContractAuditor: {e}")
    ContractAuditor = None

try:
    sys.path.append(str(APPS_DIR / "inspector"))
    from readiness_generator import ReadinessGenerator
except Exception as e:
    print(f"[WARN] Failed to load ReadinessGenerator: {e}")
    ReadinessGenerator = None

# --- RATE LIMITER (MVP) ---
RATE_LIMIT_STORE: Dict[str, List[float]] = {}
RATE_LIMIT_WINDOW = 60  # seconds
RATE_LIMIT_MAX_REQUESTS = 5  # requests per window


def _client_ip(req: Request) -> str:
    xff = req.headers.get("x-forwarded-for")
    if xff:
        return xff.split(",")[0].strip()
    return req.client.host if req.client else "unknown"


def check_rate_limit(request: Request):
    client_ip = _client_ip(request)
    
    # INSPECTOR BYPASS (Priority 6)
    if client_ip in ["127.0.0.1", "localhost", "::1"] and request.headers.get("X-Titan-Inspector") == "1":
        return

    now = time.time()
    RATE_LIMIT_STORE.setdefault(client_ip, [])
    RATE_LIMIT_STORE[client_ip] = [ts for ts in RATE_LIMIT_STORE[client_ip] if now - ts < RATE_LIMIT_WINDOW]
    if len(RATE_LIMIT_STORE[client_ip]) >= RATE_LIMIT_MAX_REQUESTS:
        raise HTTPException(status_code=429, detail="Rate limit exceeded. Slow down.")
    RATE_LIMIT_STORE[client_ip].append(now)


def load_catalog() -> dict:
    if CATALOG_PATH.exists():
        try:
            return json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
        except Exception as e:
            return {"error": f"catalog.json parse failed: {e}", "products": []}

    return {
        "products": [
            {"id": "grants", "name": "Grants & Funding", "status": "LIVE", "path": "/portal/grants"},
            {"id": "audit", "name": "Compliance Audit", "status": "LIVE", "path": "/portal/audit"},
            {"id": "hr", "name": "HR & Workforce", "status": "COMING_SOON", "path": "/portal/hr"},
        ]
    }


def _model_dump(obj: Any) -> Any:
    """
    Pydantic v1/v2 safe serializer:
    - v2: model_dump()
    - v1: dict()
    - otherwise: return as-is
    """
    if hasattr(obj, "model_dump"):
        return obj.model_dump()
    if hasattr(obj, "dict"):
        return obj.dict()
    return obj


CATALOG = load_catalog()

app = FastAPI(
    title="TITAN OS Bridge",
    description="The connectivity layer for TITAN OS.",
    version="2.2.1",
)

templates = Jinja2Templates(directory=str(TEMPLATES_DIR))


# -----------------------
# CORE ROUTES
# -----------------------
@app.get("/health")
def health():
    return {
        "status": "operational",
        "os": "TITAN v1.0",
        "dirs": {"root": str(TITAN_ROOT), "portal": str(PORTAL_DIR)},
        "io": {"root": str(IO_ROOT), "inbox": str(INBOX), "outbox": str(OUTBOX)},
    }


@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    return templates.TemplateResponse("index.html", {"request": request, "catalog": CATALOG})


# -----------------------
# PORTAL ROUTES
# -----------------------
@app.get("/portal", response_class=HTMLResponse)
async def portal_home(request: Request):
    return templates.TemplateResponse("index.html", {"request": request, "catalog": CATALOG})


@app.get("/portal/departments", response_class=HTMLResponse)
async def portal_departments(request: Request):
    return templates.TemplateResponse("departments.html", {"request": request, "catalog": CATALOG})


@app.get("/portal/grants", response_class=HTMLResponse)
async def portal_grants(request: Request):
    return templates.TemplateResponse("grants.html", {"request": request, "catalog": CATALOG})


@app.get("/portal/international", response_class=HTMLResponse)
async def portal_international(request: Request):
    return templates.TemplateResponse("international.html", {
        "request": request,
        "year": datetime.now().year, 
        "catalog": CATALOG # Pass catalog for generic generic header data if needed
    })

@app.get("/portal/audit", response_class=HTMLResponse)
async def portal_audit(request: Request):
    return templates.TemplateResponse("audit.html", {
        "request": request, 
        "catalog": CATALOG,
        "paypal_client_id": os.environ.get("PAYPAL_CLIENT_ID", "")
    })


@app.get("/portal/resources", response_class=HTMLResponse)
async def portal_resources(request: Request):
    return templates.TemplateResponse("resources.html", {"request": request, "catalog": CATALOG})


@app.get("/portal/intake", response_class=HTMLResponse)
async def portal_intake(request: Request):
    return templates.TemplateResponse("intake.html", {"request": request, "catalog": CATALOG})


@app.get("/portal/about", response_class=HTMLResponse)
async def portal_about(request: Request):
    return templates.TemplateResponse("about.html", {"request": request, "catalog": CATALOG})


# -----------------------
# DOWNLOAD HELPERS
# -----------------------
def _safe_outbox_file(filename: str) -> Path:
    """
    Resolve a filename against OUTBOX with strict traversal protection.
    """
    candidate = (OUTBOX / filename).resolve()
    outbox_root = OUTBOX.resolve()

    # must be inside OUTBOX
    if candidate == outbox_root:
        raise HTTPException(status_code=400, detail="Invalid filename")
    if outbox_root not in candidate.parents:
        raise HTTPException(status_code=400, detail="Invalid filename")

    if not candidate.exists() or not candidate.is_file():
        raise HTTPException(status_code=404, detail="File not found")

    return candidate


def _send_pdf(candidate: Path, download_name: str, disposition: str = "attachment") -> FileResponse:
    """
    Starlette/FastAPI compatible file serving.
    - disposition: 'attachment' (save) or 'inline' (view in browser)
    """
    headers = {
        "Content-Disposition": f'{disposition}; filename="{download_name}"'
    }
    return FileResponse(
        path=str(candidate),
        media_type="application/pdf",
        headers=headers,
    )


@app.get("/debug/outbox")
async def debug_outbox():
    """
    Quick debug endpoint: lists last 30 OUTBOX files.
    Remove/disable before public deployment.
    """
    guard_debug_route() # SECURE
    files = []
    for p in sorted(OUTBOX.glob("*"), key=lambda x: x.stat().st_mtime, reverse=True)[:30]:
        try:
            files.append({
                "name": p.name,
                "size": p.stat().st_size,
                "modified": datetime.fromtimestamp(p.stat().st_mtime).isoformat(),
            })
        except Exception:
            continue
    return {"outbox": str(OUTBOX), "count": len(files), "files": files}


@app.get("/download/grant/{filename}")
async def download_grant(filename: str):
    if not filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF downloads are allowed")

    candidate = _safe_outbox_file(filename)
    print(f"[DOWNLOAD][GRANT] OK -> {candidate}")
    return _send_pdf(candidate, filename, disposition="inline")


@app.get("/download/audit/{filename}")
async def download_audit(filename: str):
    if not filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF downloads are allowed")

    candidate = _safe_outbox_file(filename)
    print(f"[DOWNLOAD][AUDIT] OK -> {candidate}")
    return _send_pdf(candidate, filename, disposition="inline")


# -----------------------
# EXECUTION ENDPOINTS
# -----------------------
@app.post("/api/grants/tinns/generate")
async def generate_grant(
    request: Request,
    project_cost: float = Form(...),
    company_name: str = Form(...),
    project_name: Optional[str] = Form(None),
    project_summary: Optional[str] = Form(None),
    timeline: Optional[str] = Form(None),
    # V2 Eligibility Params
    inc_year: Optional[int] = Form(None),
    turnover_range: Optional[str] = Form(None),
    staff_count: Optional[int] = Form(None),
    sector: Optional[str] = Form(None),
    # Logic Map Additions
    documentation_ready: Optional[str] = Form(None),
    urgency_level: Optional[str] = Form(None),
    company_age_years: Optional[float] = Form(None),
):
    try:
        check_rate_limit(request)

        if project_cost < 0:
            raise HTTPException(status_code=400, detail="project_cost must be >= 0")

        company_name_clean = (company_name or "").strip()
        if not company_name_clean:
            raise HTTPException(status_code=400, detail="company_name is required")

        generator = TinnsGenerator()
        
        # Pass eligibility data to simulation? (Ideally yes, but for MVP PDF generation we pass it to generate_proposal)
        # For now, simulation remains financial, but the PDF will contain the Eligibility Matrix.

        # LOGIC MAP UPDATE: 
        # We no longer "simulate" multiple scenarios (Hardware vs Software).
        # We just generate the definitive Plan based on the Logic Map rules.
        
        # Create a dummy scenario object for the response (frontend expects it)
        best_scenario = {
            "scenario": "Logic Map Strategy",
            "refund_amount": 0.0, 
            "probability_of_approval": 0.0,
            "risk_factors": [],
            "recommendation": "See PDF for details"
        }



        proj_name = (project_name or "").strip() or "Technology Project"

        try:
            file_path = Path(generator.generate_full_application(
                project_name=proj_name, 
                cost=project_cost, 
                company_name=company_name_clean,
                summary=project_summary,
                timeline=timeline,
                eligibility_data={
                    "inc_year": inc_year,
                    "turnover_band": turnover_range, # Mapped from UI 'turnover_range'
                    "staff": staff_count,
                    "sector": sector,
                    "documentation_ready": documentation_ready,
                    "urgency_level": urgency_level,
                    "company_age_years": company_age_years
                }
            ))
        except Exception as e:
            import traceback
            traceback.print_exc()
            raise HTTPException(status_code=500, detail=f"Generator crashed: {str(e)}")
        print(f"[GRANT] Verdict generated -> {file_path}")

        if not file_path.exists():
            raise HTTPException(status_code=500, detail="Proposal generation failed (file missing)")

        if file_path.suffix.lower() != ".pdf":
            raise HTTPException(status_code=500, detail="Proposal generation failed (not a PDF)")

        return {
            "status": "success",
            "best_outcome": _model_dump(best_scenario),
            "download_url": f"/download/grant/{file_path.name}",
            "message": f"Optimization Complete. Best Strategy: {getattr(best_scenario, 'scenario', 'N/A')}",
        }
    except HTTPException:
        raise
    except Exception as e:
        return JSONResponse(status_code=500, content={"status": "error", "message": str(e)})


def _extract_text_from_pdf_bytes(pdf_bytes: bytes) -> str:
    try:
        from pypdf import PdfReader
        import io
        print(f"[DEBUG] Starting PDF extraction. Bytes: {len(pdf_bytes)}")
        reader = PdfReader(io.BytesIO(pdf_bytes))
        parts = []
        for i, page in enumerate(reader.pages):
            t = page.extract_text() or ""
            if t.strip():
                parts.append(t)

        full_text = "\n\n".join(parts).strip()
        print(f"[DEBUG] Extraction complete. Pages: {len(reader.pages)}, Text Length: {len(full_text)}")
        return full_text
    except ImportError:
        print("[ERROR] pypdf not installed.")
        return ""
    except Exception as e:
        print(f"[ERROR] PDF Extraction failed: {e}")
        return ""


@app.post("/api/audit/upload")
async def audit_upload(request: Request, email: str = Form(...), file: UploadFile = File(...)):
    try:
        check_rate_limit(request)  # FIX: Pass request object, not IP string

        # --- CRM LOGGING ---
        lead_entry = {
            "timestamp": datetime.now().isoformat(),
            "email": email,
            "filename": file.filename,
            "ip": _client_ip(request),
            "tier_interest": "Tier 1 (Free Scan)"
        }
        leads_path = IO_ROOT / "leads.jsonl"
        with open(leads_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(lead_entry) + "\n")
        # -------------------

        content_bytes = await file.read()

        if len(content_bytes) > 10_000_000:
            raise HTTPException(status_code=413, detail="File too large for MVP (max 10MB).")

        filename = file.filename or "upload"
        lower = filename.lower()

        extracted_text = ""
        if (file.content_type or "").startswith("text/") or lower.endswith(".txt"):
            extracted_text = content_bytes.decode("utf-8", errors="ignore").strip()
        elif file.content_type == "application/pdf" or lower.endswith(".pdf"):
            extracted_text = _extract_text_from_pdf_bytes(content_bytes)
        else:
            raise HTTPException(status_code=415, detail="Unsupported file type. Upload .txt or .pdf")

        auditor = ContractAuditor()

        is_mock_file = "OA - 010917" in filename

        if (lower.endswith(".pdf") or file.content_type == "application/pdf") and not extracted_text and not is_mock_file:
            print(f"[WARN] No text extracted from PDF: {filename}")
            findings = {
                "filename": filename,
                "risk": "MANUAL REVIEW",
                "flags": [{
                    "severity": "INFO",
                    "issue": "Scanned Document Detected",
                    "evidence": "Automated text extraction yielded no results. This document appears to be a scan or image-only PDF."
                }],
                "summary": "This document requires manual review as no machine-readable text was found.",
                "disclaimer": "TITAN requires text-searchable PDFs for automated risk detection."
            }
        else:
            findings = auditor.analyze_text(extracted_text, filename=filename)

        report_path = Path(auditor.generate_report_pdf(findings, original_filename=filename))
        print(f"[AUDIT] report -> {report_path}")

        if not report_path.exists():
            raise HTTPException(status_code=500, detail="Report generation failed (file missing).")

        if report_path.suffix.lower() != ".pdf":
            raise HTTPException(status_code=500, detail="Report generation failed (not a PDF).")

        return {
            "status": "success",
            "result": findings,
            # "download_url": f"/download/audit/{report_path.name}", # SECURE: Don't reveal URL
            "report_filename": report_path.name, # Internal ref only
            "message": "Audit complete. Risks detected. Report locked."
        }

    except HTTPException:
        raise
    except Exception as e:
        return JSONResponse(status_code=500, content={"status": "error", "message": str(e)})


@app.post("/api/oracle/generate-report")
async def generate_readiness_report(
    request: Request,
    company_name: str = Form("Client"),
    jurisdiction: str = Form("Mauritius"),
    score: int = Form(...),
    band: str = Form(...),
    percentile: str = Form(...),
    fail_rate: str = Form(...),
    cost_total: str = Form(...),
    insights: str = Form(...) # JSON String
):
    try:
        check_rate_limit(request)
        
        # Parse insights JSON
        try:
            insights_list = json.loads(insights)
        except:
            insights_list = []

        generator = ReadinessGenerator()
        path = Path(generator.generate_report(
            company_name=company_name,
            jurisdiction=jurisdiction,
            score=score,
            band=band,
            percentile=percentile,
            fail_rate=fail_rate,
            cost_total=cost_total,
            insights=insights_list
        ))
        
        print(f"[ORACLE] Report generated -> {path}")
        
        if not path.exists():
             raise HTTPException(status_code=500, detail="Report generation failed")
             
        return {
            "status": "success",
            "download_url": f"/download/audit/{path.name}",
            "filename": path.name
        }
    except Exception as e:
        print(f"[ERROR] Oracle Gen Failed: {e}")
        return JSONResponse(status_code=500, content={"status": "error", "message": str(e)})


@app.post("/api/oracle/generate-report")
async def generate_readiness_report(
    request: Request,
    company_name: str = Form("Client"),
    jurisdiction: str = Form("Mauritius"),
    score: int = Form(...),
    band: str = Form(...),
    percentile: str = Form(...),
    fail_rate: str = Form(...),
    cost_total: str = Form(...),
    insights: str = Form(...) # JSON String
):
    try:
        check_rate_limit(request)
        
        # Parse insights JSON
        try:
            insights_list = json.loads(insights)
        except:
            insights_list = []

        generator = ReadinessGenerator()
        path = Path(generator.generate_report(
            company_name=company_name,
            jurisdiction=jurisdiction,
            score=score,
            band=band,
            percentile=percentile,
            fail_rate=fail_rate,
            cost_total=cost_total,
            insights=insights_list
        ))
        
        print(f"[ORACLE] Report generated -> {path}")
        
        if not path.exists():
             raise HTTPException(status_code=500, detail="Report generation failed")
             
        return {
            "status": "success",
            "download_url": f"/download/audit/{path.name}",
            "filename": path.name
        }
    except Exception as e:
        print(f"[ERROR] Oracle Gen Failed: {e}")
        return JSONResponse(status_code=500, content={"status": "error", "message": str(e)})


# --- INSPECTOR ENDPOINTS (Priority 6) ---

# --- SECURITY CONSTITUTION ---
PUBLIC_MODE = os.environ.get("TITAN_PUBLIC_MODE") == "1"

def guard_debug_route():
    if PUBLIC_MODE:
        raise HTTPException(status_code=403, detail="Endpoint disabled in PUBLIC_MODE")

# --- DATA HELPERS ---
def read_jsonl_tail(path: Path, n=10):
    guard_debug_route() # SECURE
    if not path.exists():
        return []
    lines = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception:
        return []
    
    # Parse last n lines
    results = []
    for line in lines[-n:]:
        try:
            results.append(json.loads(line))
        except:
            continue
    return list(reversed(results)) # Newest first

@app.get("/api/doctor/ledger")
async def get_doctor_ledger():
    guard_debug_route() # SECURE
    root = Path(os.environ.get("TITAN_ROOT", r"F:\AION-ZERO\TITAN"))
    ledger_path = root / "apps" / "doctor" / "ledger.jsonl"
    return read_jsonl_tail(ledger_path, n=20)

@app.get("/api/voyager/roadmap")
async def get_voyager_roadmap():
    guard_debug_route() # SECURE
    root = Path(os.environ.get("TITAN_ROOT", r"F:\AION-ZERO\TITAN"))
    # Two sources: az_roadmap (Curated) or signals (Raw). Let's show Roadmap.
    roadmap_path = root / "az_roadmap.jsonl"
    return read_jsonl_tail(roadmap_path, n=20)

@app.get("/api/system/logs")
async def get_system_logs():
    guard_debug_route() # SECURE
    root = Path(os.environ.get("TITAN_ROOT", r"F:\AION-ZERO\TITAN"))
    log_path = root / "apps" / "voyager" / "data" / "system.log"
    if not log_path.exists():
        return ["Waiting for Cronos to start..."]
        
    try:
        with open(log_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        return [line.strip() for line in lines[-50:]]
    except Exception as e:
        return [f"Error reading logs: {e}"]

@app.get("/api/inspector/latest")
async def get_latest_audit_json():
    guard_debug_route() # SECURE
    root = Path(os.environ.get("TITAN_ROOT", r"F:\AION-ZERO\TITAN"))
    report_path = root / "apps" / "inspector" / "reports" / "latest" / "audit.json"
    
    if not report_path.exists():
        return {"status": "error", "message": f"No audit report found at {report_path}. Run inspector."}
    with open(report_path, "r") as f:
        data = json.load(f)
        if not PUBLIC_MODE:
            data["_debug_path"] = str(report_path)
        return data

@app.get("/portal/health", response_class=HTMLResponse)
async def get_health_dashboard(request: Request):
    return templates.TemplateResponse("health.html", {"request": request})

@app.get("/portal/vault", response_class=HTMLResponse)
async def get_vault_ui(request: Request):
    check_rate_limit(request) # Security
    return templates.TemplateResponse("vault.html", {"request": request})


# -----------------------
# CATCH-ALL (Fixes 404s)
# -----------------------
@app.exception_handler(404)
async def custom_404_handler(request: Request, exc: HTTPException):
    # Redirect 404s to Home
    return templates.TemplateResponse("index.html", {"request": request, "catalog": CATALOG})

@app.get("/{catchall:path}", include_in_schema=False)
async def catch_all_route(request: Request, catchall: str):
    # Catch any leftover paths
    return templates.TemplateResponse("index.html", {"request": request, "catalog": CATALOG})
