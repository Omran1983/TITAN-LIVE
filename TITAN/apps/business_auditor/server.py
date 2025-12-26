# server.py — Production-safe FastAPI service for "Agreement Risk Verdict (SMEs)"
# - Safe download via opaque token (no path traversal)
# - In-memory PDF streaming (no disk writes)
# - ENV-based base URL
# - doc_type enum
# - strict request + field size limits (even if Content-Length missing)
# - consistent JSON error envelope
# - bounded in-memory TTL store with eviction (max items + max bytes)
# - conservative PDF sanitization
# - Expanded Risk Logic (keyword/regex heuristics)
# - DEBUG-gated exception hints
# - Minimal IP rate limiter (optional)

import os
import re
import time
import uuid
import secrets
import threading
from io import BytesIO
from enum import Enum
from typing import List, Optional, Dict, Tuple

import uvicorn
from fastapi import FastAPI, HTTPException, Body, Request
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel, Field
from fpdf import FPDF


# -------------------------
# Config helpers
# -------------------------

def _env_int(name: str, default: int) -> int:
    try:
        return int(str(os.environ.get(name, default)).strip())
    except Exception:
        return default

def _env_str(name: str, default: str) -> str:
    v = os.environ.get(name, default)
    return str(v).strip()

def _env_bool(name: str, default: bool = False) -> bool:
    v = str(os.environ.get(name, "1" if default else "0")).strip().lower()
    return v in ("1", "true", "yes", "y", "on")

APP_TITLE = _env_str("APP_TITLE", "Agreement Risk Verdict (SMEs)")
APP_VERSION = _env_str("APP_VERSION", "3.2.0")
PUBLIC_BASE_URL = _env_str("PUBLIC_BASE_URL", "http://localhost:8000").rstrip("/")

DEBUG = _env_bool("DEBUG", False)

MAX_REQUEST_BYTES = _env_int("MAX_REQUEST_BYTES", 1_000_000)   # 1MB body cap
MAX_TEXT_CHARS = _env_int("MAX_TEXT_CHARS", 200_000)           # text cap
MAX_FLAGS = _env_int("MAX_FLAGS", 50)                          # findings cap
PDF_TTL_SECONDS = _env_int("PDF_TTL_SECONDS", 30 * 60)         # 30 min

MAX_STORE_ITEMS = _env_int("MAX_STORE_ITEMS", 500)             # max PDFs held
MAX_STORE_BYTES = _env_int("MAX_STORE_BYTES", 50_000_000)      # 50MB total PDFs

ALLOW_ORIGIN = _env_str("ALLOW_ORIGIN", "").strip()            # optional CORS allow

# Minimal rate limiting (set to 0 to disable)
RATE_LIMIT_PER_MIN = _env_int("RATE_LIMIT_PER_MIN", 60)        # requests per IP per minute


# -------------------------
# Error envelope (consistent)
# -------------------------

class ApiError(BaseModel):
    code: str
    message: str
    hint: Optional[str] = None

def _dump(model: BaseModel) -> dict:
    md = getattr(model, "model_dump", None)
    return md() if callable(md) else model.dict()

def _error(status: int, code: str, message: str, hint: Optional[str] = None) -> None:
    raise HTTPException(
        status_code=status,
        detail=_dump(ApiError(code=code, message=message, hint=hint))
    )

def _json_error(status: int, code: str, message: str, hint: Optional[str] = None) -> JSONResponse:
    return JSONResponse(status_code=status, content={"error": _dump(ApiError(code=code, message=message, hint=hint))})


# -------------------------
# Models
# -------------------------

class DocType(str, Enum):
    contractor_agreement = "contractor_agreement"
    employment_contract = "employment_contract"
    service_agreement = "service_agreement"
    nda = "nda"
    terms_conditions = "terms_conditions"
    other = "other"

class RiskSeverity(str, Enum):
    CRITICAL = "CRITICAL"
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"

class DocumentInput(BaseModel):
    doc_type: DocType = Field(..., description="Type of the agreement/document.")
    text_content: str = Field(..., description="Paste extracted text content of the agreement.")
    jurisdiction: str = Field(default="Global (Risk Pattern Audit)", max_length=120)

class RiskFlag(BaseModel):
    severity: RiskSeverity
    category: str = Field(..., max_length=40)
    issue: str = Field(..., max_length=140)
    audit_note: str = Field(..., max_length=400)
    bad_clause_snippet: Optional[str] = Field(default=None, max_length=400)

class AuditReport(BaseModel):
    report_id: str
    verdict_color: str  # RED/AMBER/GREEN
    verdict_title: str
    risk_score: int     # 0..100
    auditor_summary: str
    tone_mode: str      # AUDITOR/CONSULTANT
    flags: List[RiskFlag]
    pdf_download_url: Optional[str] = None


# -------------------------
# Bounded in-memory PDF store (token -> (created_at, pdf_bytes, report_id))
# -------------------------

_STORE: Dict[str, Tuple[float, bytes, str]] = {}
_STORE_BYTES = 0
_LOCK = threading.Lock()

def _cleanup_and_evict(now: float) -> None:
    global _STORE_BYTES

    expired = [k for k, (ts, _, _) in _STORE.items() if (now - ts) > PDF_TTL_SECONDS]
    for k in expired:
        _, b, _rid = _STORE.pop(k, (0.0, b"", ""))
        _STORE_BYTES -= len(b)

    def over_caps() -> bool:
        return (len(_STORE) > MAX_STORE_ITEMS) or (_STORE_BYTES > MAX_STORE_BYTES)

    if over_caps():
        items = sorted(_STORE.items(), key=lambda kv: kv[1][0])  # oldest first
        idx = 0
        while over_caps() and idx < len(items):
            k, (_, b, _rid) = items[idx]
            _STORE.pop(k, None)
            _STORE_BYTES -= len(b)
            idx += 1

    if _STORE_BYTES < 0:
        _STORE_BYTES = 0

def _store_pdf(pdf_bytes: bytes, report_id: str) -> str:
    global _STORE_BYTES
    now = time.time()

    if len(pdf_bytes) > MAX_STORE_BYTES:
        _error(413, "pdf_too_large", "Generated PDF too large to store.", hint="Reduce findings or input size.")

    with _LOCK:
        _cleanup_and_evict(now)

        # collision-safe token generation
        for _ in range(5):
            token = secrets.token_urlsafe(18)
            if token not in _STORE:
                break
        else:
            _error(503, "store_busy", "Temporary storage unavailable. Try again.")

        _STORE[token] = (now, pdf_bytes, report_id)
        _STORE_BYTES += len(pdf_bytes)
        _cleanup_and_evict(now)

    return token

def _get_pdf(token: str) -> Tuple[bytes, str]:
    now = time.time()
    with _LOCK:
        _cleanup_and_evict(now)
        item = _STORE.get(token)
        if not item:
            _error(404, "not_found", "Report not found or expired.", hint=f"TTL seconds: {PDF_TTL_SECONDS}")
        _, pdf_bytes, report_id = item
        return pdf_bytes, report_id


# -------------------------
# Minimal in-memory IP rate limiter (optional)
# -------------------------

_RL: Dict[str, Tuple[int, float]] = {}  # ip -> (count, window_start_epoch)
_RL_LOCK = threading.Lock()

def _rate_limit(ip: str) -> None:
    if RATE_LIMIT_PER_MIN <= 0:
        return
    now = time.time()
    window = 60.0
    with _RL_LOCK:
        count, start = _RL.get(ip, (0, now))
        if now - start >= window:
            _RL[ip] = (1, now)
            return
        if count + 1 > RATE_LIMIT_PER_MIN:
            _error(429, "rate_limited", "Too many requests.", hint="Slow down and retry in ~60 seconds.")
        _RL[ip] = (count + 1, start)


# -------------------------
# App
# -------------------------

app = FastAPI(title=APP_TITLE, version=APP_VERSION)

if ALLOW_ORIGIN:
    from fastapi.middleware.cors import CORSMiddleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[ALLOW_ORIGIN],
        allow_credentials=True,
        allow_methods=["GET", "POST", "OPTIONS"],
        allow_headers=["*"],
    )

@app.middleware("http")
async def body_size_limiter(request: Request, call_next):
    if request.method in ("POST", "PUT", "PATCH"):
        body = await request.body()
        if len(body) > MAX_REQUEST_BYTES:
            return _json_error(413, "payload_too_large", "Request body too large.", hint=f"Max bytes: {MAX_REQUEST_BYTES}")

        async def receive():
            return {"type": "http.request", "body": body, "more_body": False}
        request._receive = receive  # type: ignore[attr-defined]

    resp = await call_next(request)
    resp.headers["Cache-Control"] = "no-store"
    resp.headers["X-Content-Type-Options"] = "nosniff"
    return resp

@app.exception_handler(HTTPException)
async def http_exception_handler(_: Request, exc: HTTPException):
    if isinstance(exc.detail, dict) and ("code" in exc.detail and "message" in exc.detail):
        return JSONResponse(status_code=exc.status_code, content={"error": exc.detail})
    return _json_error(exc.status_code, "http_error", "Request failed.", hint=str(exc.detail) if DEBUG else None)

@app.exception_handler(Exception)
async def unhandled_exception_handler(_: Request, exc: Exception):
    return _json_error(500, "internal_error", "Unexpected server error.", hint=str(exc)[:200] if DEBUG else None)

@app.get("/health")
def health():
    return {"ok": True, "name": APP_TITLE, "version": APP_VERSION}


# -------------------------
# Input normalization
# -------------------------

def _normalize_text(text: str) -> str:
    if text is None:
        _error(400, "missing_text", "text_content is required.")
    if not isinstance(text, str):
        _error(400, "bad_text", "text_content must be a string.")
    if len(text) > MAX_TEXT_CHARS:
        _error(413, "text_too_large", "Document text is too large.", hint=f"Max chars: {MAX_TEXT_CHARS}")
    if not text.strip():
        _error(400, "empty_text", "Document text is empty.")
    return text


# -------------------------
# PDF generation (in-memory)
# -------------------------

class PDFReport(FPDF):
    def header(self):
        self.set_font("Arial", "B", 12)
        self.cell(0, 10, "TITAN AUDIT CERTIFICATE", 0, 1, "C")
        self.ln(3)

    def footer(self):
        self.set_y(-15)
        self.set_font("Arial", "I", 8)
        self.cell(0, 10, "Generated by TITAN Risk Scanner — Not Legal Advice", 0, 0, "C")

def _safe_text(s: str, max_len: int) -> str:
    if not s:
        return ""
    s = "".join(ch if (ch.isprintable() or ch in "\n\t") else " " for ch in s)
    return s[:max_len]

def _pdf_bytes(report: AuditReport, meta: DocumentInput) -> bytes:
    pdf = PDFReport()
    pdf.add_page()

    pdf.set_font("Arial", "", 11)
    pdf.multi_cell(0, 7, f"Document Type: {meta.doc_type.value}")
    pdf.multi_cell(0, 7, f"Jurisdiction (display): {_safe_text(meta.jurisdiction, 120)}")
    pdf.multi_cell(0, 7, f"Report ID: {report.report_id}")
    pdf.ln(3)

    pdf.set_font("Arial", "B", 16)
    if report.verdict_color == "RED":
        pdf.set_text_color(200, 0, 0)
    elif report.verdict_color == "AMBER":
        pdf.set_text_color(200, 120, 0)
    else:
        pdf.set_text_color(0, 150, 0)

    pdf.cell(0, 10, f"VERDICT: {report.verdict_title} ({report.risk_score}/100)", 0, 1, "C")
    pdf.set_text_color(0, 0, 0)
    pdf.ln(6)

    pdf.set_font("Arial", "", 12)
    pdf.multi_cell(0, 8, f"Summary: {_safe_text(report.auditor_summary, 900)}")
    pdf.ln(4)

    pdf.set_font("Arial", "B", 13)
    pdf.cell(0, 9, "Audit Findings:", 0, 1)

    for flag in report.flags[:MAX_FLAGS]:
        pdf.set_font("Arial", "B", 12)
        if flag.severity == RiskSeverity.CRITICAL:
            pdf.set_text_color(200, 0, 0)
        elif flag.severity == RiskSeverity.HIGH:
            pdf.set_text_color(160, 60, 0)
        else:
            pdf.set_text_color(0, 0, 0)

        pdf.multi_cell(0, 7, f"[{flag.severity}] {flag.issue}")
        pdf.set_text_color(0, 0, 0)

        pdf.set_font("Arial", "", 11)
        pdf.multi_cell(0, 6, f"Category: {flag.category}")
        pdf.multi_cell(0, 6, f"Note: {_safe_text(flag.audit_note, 500)}")
        if flag.bad_clause_snippet:
            pdf.set_font("Courier", "", 9)
            pdf.multi_cell(0, 5, f"Snippet: \"{_safe_text(flag.bad_clause_snippet, 250)}\"")
        pdf.ln(3)

    raw = pdf.output(dest="S")
    return raw.encode("latin-1", errors="replace") if isinstance(raw, str) else bytes(raw)


# -------------------------
# Risk logic (keyword/regex heuristics)
# -------------------------

def _snippet(text: str, pattern: re.Pattern, max_len: int = 260) -> Optional[str]:
    m = pattern.search(text)
    if not m:
        return None
    start = max(0, m.start() - 80)
    end = min(len(text), m.end() + 180)
    s = re.sub(r"\s+", " ", text[start:end].strip())
    return s[:max_len]

def _add(flags: List[RiskFlag], severity: RiskSeverity, category: str, issue: str, note: str, snip: Optional[str] = None):
    flags.append(RiskFlag(
        severity=severity,
        category=category,
        issue=issue,
        audit_note=note,
        bad_clause_snippet=snip
    ))

RX = {
    "unlimited_indemnity": re.compile(r"\bunlimited\b.{0,80}\bindemnif", re.IGNORECASE | re.DOTALL),
    "limitation_liability": re.compile(r"\blimit(?:ation)? of liability\b|\bliability cap\b", re.IGNORECASE),
    "explicit_uncapped": re.compile(r"\buncapped\b|\bwithout limit\b", re.IGNORECASE),
    "auto_renew": re.compile(r"\bautomatic(?:ally)? renew", re.IGNORECASE),
    "non_compete": re.compile(r"\bnon-?compete\b|\brestrictive covenant\b", re.IGNORECASE),
    "two_years": re.compile(r"\b(2\s*years|24\s*months)\b", re.IGNORECASE),
    "set_hours": re.compile(r"\b(9am|09:00|5pm|17:00|set hours|working hours)\b", re.IGNORECASE),
    "exclusive": re.compile(r"\bexclusive\b|\bsolely\b", re.IGNORECASE),
    "termination_convenience": re.compile(r"\btermination for convenience\b|\bterminate on notice\b", re.IGNORECASE),
    "net60": re.compile(r"\bnet\s*(60|90)\b", re.IGNORECASE),
    "confidential": re.compile(r"\bconfidential\b|\bnda\b", re.IGNORECASE),
    "force_majeure": re.compile(r"\bforce majeure\b", re.IGNORECASE),
    "binding_arbitration": re.compile(r"\bbinding\b.{0,40}\barbitration\b", re.IGNORECASE | re.DOTALL),
    "governing_law": re.compile(r"\bgoverning law\b|\bjurisdiction\b|\bvenue\b", re.IGNORECASE),
    "warranty_disclaimer": re.compile(r"\bas is\b|\bno warranties\b|\bwithout warranty\b", re.IGNORECASE),
    "ip_assignment": re.compile(r"\bwork for hire\b|\bassign(?:s|ment)? all rights\b", re.IGNORECASE),
}

def _scan(text: str, doc_type: DocType) -> List[RiskFlag]:
    flags: List[RiskFlag] = []
    tl = text.lower()

    # CRITICAL
    if RX["unlimited_indemnity"].search(text):
        _add(flags, RiskSeverity.CRITICAL, "Legal", "Unlimited Indemnity Exposure",
             "Uncapped exposure. Negotiate a liability cap (often fees paid / contract value).",
             _snippet(text, RX["unlimited_indemnity"]))
    if RX["explicit_uncapped"].search(text) and RX["limitation_liability"].search(text) is None:
        _add(flags, RiskSeverity.CRITICAL, "Legal", "Explicit Uncapped Liability (No Liability Cap Clause)",
             "Explicit uncapped liability language detected. Add a limitation of liability clause.",
             _snippet(text, RX["explicit_uncapped"]))
    if not RX["termination_convenience"].search(text):
        _add(flags, RiskSeverity.CRITICAL, "Operational", "Locked In (No Termination on Notice/Convenience)",
             "No clean exit clause. Add termination on notice (e.g., 30 days) or termination for convenience.")
    if doc_type == DocType.contractor_agreement and RX["exclusive"].search(text):
        _add(flags, RiskSeverity.CRITICAL, "Tax/Compliance", "Exclusivity Clause (Employee Signal)",
             "Exclusivity can look like employment. Aim for non-exclusive engagement.",
             _snippet(text, RX["exclusive"]))
    if doc_type == DocType.contractor_agreement and RX["set_hours"].search(text):
        _add(flags, RiskSeverity.CRITICAL, "Tax/Compliance", "Fixed Hours / Schedule (Employee Signal)",
             "Fixed schedules can signal employment. Contractors usually control hours/methods.",
             _snippet(text, RX["set_hours"]))

    # HIGH
    if RX["auto_renew"].search(text):
        _add(flags, RiskSeverity.HIGH, "Commercial", "Auto-Renewal Clause",
             "Auto-renew can trap you. Require reminder + clear cancellation window (e.g., 30 days).",
             _snippet(text, RX["auto_renew"]))
    if RX["non_compete"].search(text) and RX["two_years"].search(text):
        _add(flags, RiskSeverity.HIGH, "HR/Labor", "Excessive Non-Compete Duration",
             "2 years is often unenforceable and commercially harmful. Negotiate 6–12 months.",
             _snippet(text, RX["non_compete"]))
    if doc_type != DocType.nda and RX["confidential"].search(text) is None:
        _add(flags, RiskSeverity.HIGH, "Legal", "No Confidentiality Clause Detected",
             "Missing confidentiality protection. Add mutual confidentiality or a separate NDA.")

    # MEDIUM
    if RX["net60"].search(text):
        _add(flags, RiskSeverity.MEDIUM, "Financial", "Long Payment Terms (Net 60/90)",
             "Long terms strain cashflow. Prefer Net 30 or milestone-based payments.",
             _snippet(text, RX["net60"]))
    if RX["force_majeure"].search(text) is None:
        _add(flags, RiskSeverity.MEDIUM, "Legal", "Missing Force Majeure",
             "No protection for unexpected events (pandemics, disasters). Add standard clause.")
    if RX["binding_arbitration"].search(text):
        _add(flags, RiskSeverity.MEDIUM, "Legal", "Binding Arbitration Requirement",
             "You may waive court/jury rights. Ensure venue, rules, costs are acceptable.",
             _snippet(text, RX["binding_arbitration"]))
    if RX["governing_law"].search(text) is None:
        _add(flags, RiskSeverity.MEDIUM, "Legal", "Undefined Governing Law / Venue",
             "Contract should specify governing law and venue/jurisdiction to avoid surprises.")
    if RX["warranty_disclaimer"].search(text):
        _add(flags, RiskSeverity.MEDIUM, "Commercial", "Broad Warranty Disclaimer ('AS IS')",
             "Broad disclaimers reduce remedies. Ensure minimum warranties or acceptance criteria.",
             _snippet(text, RX["warranty_disclaimer"]))
    if doc_type in (DocType.service_agreement, DocType.contractor_agreement) and RX["ip_assignment"].search(text) is None:
        _add(flags, RiskSeverity.MEDIUM, "IP", "Missing IP Assignment / Work-for-Hire Language",
             "You may not own deliverables. Add work-for-hire and IP assignment.")

    return flags[:MAX_FLAGS]


def _score(flags: List[RiskFlag]) -> int:
    score = 100
    for f in flags:
        if f.severity == RiskSeverity.CRITICAL:
            score -= 30
        elif f.severity == RiskSeverity.HIGH:
            score -= 15
        elif f.severity == RiskSeverity.MEDIUM:
            score -= 5
        else:
            score -= 2
    return max(0, score)

def _verdict(score: int) -> Tuple[str, str, str, str]:
    if score < 60:
        return ("RED", "DO NOT SIGN (HIGH RISK)",
                "Critical risks detected under the universal framework. Renegotiate before signing.",
                "CONSULTANT")
    if score < 90:
        return ("AMBER", "PROCEED WITH CAUTION",
                "Material risks found. Several clauses are non-standard or trap-prone. Review edits suggested.",
                "AUDITOR")
    return ("GREEN", "AUDIT PASSED",
            "No major red flags detected under the universal framework.",
            "AUDITOR")

def _download_url(token: str) -> Optional[str]:
    if not PUBLIC_BASE_URL:
        return None
    return f"{PUBLIC_BASE_URL}/download/{token}.pdf"


# -------------------------
# Endpoints
# -------------------------

@app.post("/scan", response_model=AuditReport, operation_id="scan_agreement")
def scan_agreement(payload: DocumentInput = Body(...), request: Request = None):
    ip = (request.client.host if request and request.client else "unknown")
    _rate_limit(ip)

    text = _normalize_text(payload.text_content)

    flags = _scan(text, payload.doc_type)
    score = _score(flags)
    color, title, summary, tone = _verdict(score)

    report_id = uuid.uuid4().hex[:10]
    report = AuditReport(
        report_id=report_id,
        verdict_color=color,
        verdict_title=title,
        risk_score=score,
        auditor_summary=summary,
        tone_mode=tone,
        flags=flags,
        pdf_download_url=None,
    )

    pdf = _pdf_bytes(report, payload)
    token = _store_pdf(pdf, report_id=report_id)
    report.pdf_download_url = _download_url(token)
    return report

@app.get("/download/{token}.pdf")
def download_pdf(token: str):
    if not token or len(token) > 128:
        _error(400, "bad_token", "Invalid token.")
    pdf_bytes, report_id = _get_pdf(token)

    buf = BytesIO(pdf_bytes)
    headers = {
        "Content-Disposition": f'attachment; filename="titan_audit_{report_id}.pdf"',
        "Cache-Control": "no-store",
    }
    return StreamingResponse(buf, media_type="application/pdf", headers=headers)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=_env_int("PORT", 8000))
