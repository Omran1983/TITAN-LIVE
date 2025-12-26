import json
import time
from pathlib import Path

import streamlit as st
from dotenv import load_dotenv

from titan_social.config import Settings
from titan_social.types import GraphicRequest
from titan_social.dispatcher import dispatch_platform
from titan_social.prompt import build_locked_prompt
from titan_social.provider_openai import OpenAIImageProvider
from titan_social.provider_hf import HFImageProvider
from titan_social.provider_local import LocalTemplateProvider
from titan_social.provider_replicate import ReplicateImageProvider
from titan_social.logging_utils import ensure_dirs, log_event
from titan_social.validators import validate_lane1_image

MAX_ATTEMPTS = 2


def load_recent_events(log_dir: str, n: int = 50):
    p = Path(log_dir) / "titan_social_events.jsonl"
    if not p.exists():
        return []
    lines = p.read_text(encoding="utf-8").splitlines()
    tail = lines[-n:] if len(lines) >= n else lines
    out = []
    for ln in reversed(tail):
        try:
            out.append(json.loads(ln))
        except Exception:
            continue
    return out


def run_one(req: GraphicRequest, s: Settings):
    ensure_dirs(s.out_dir, s.log_dir)
    dispatch = dispatch_platform(req.platform)

    prompt = build_locked_prompt(
        industry=req.industry,
        main_text=req.main_text,
        brand_color_hex=req.brand_color_hex,
        platform=req.platform,
    )



    if s.provider_type == "replicate":
        provider = ReplicateImageProvider(api_key=s.replicate_token, model=s.image_model)
    elif s.provider_type == "hf":
        provider = HFImageProvider(api_key=s.hf_token, model=s.image_model)
    elif s.provider_type == "local":
        provider = LocalTemplateProvider()
    else:
        provider = OpenAIImageProvider(api_key=s.openai_api_key, model=s.image_model)

    attempts = 0
    last_fail_reason = None
    last_artifact_path = None

    while attempts < MAX_ATTEMPTS:
        attempts += 1
        try:
            img_bytes = provider.generate_png(
                prompt=prompt,
                width=dispatch.width,
                height=dispatch.height,
            )

            artifact_name = f"{req.platform}_{req.brand_name.replace(' ', '_')}_{int(time.time())}_{attempts}.png"
            artifact_path = Path(s.out_dir) / artifact_name
            artifact_path.write_bytes(img_bytes)
            last_artifact_path = str(artifact_path)

            verdict, warnings = validate_lane1_image(
                image_path=str(artifact_path),
                expected_width=dispatch.width,
                expected_height=dispatch.height,
                expected_aspect_ratio=dispatch.aspect_ratio,
                brand_color_hex=req.brand_color_hex,

                safezone_margin=s.safezone_margin,
                safezone_busyness_threshold=s.safezone_busyness_threshold,

                enable_ocr=s.enable_ocr,
                ocr_confidence=s.ocr_confidence,
                ocr_require_text=s.ocr_require_text,
                ocr_enforce_safezone=s.ocr_enforce_safezone,
            )

            event = {
                "status": verdict.status,
                "reason": verdict.reason,
                "attempt": attempts,
                "platform": req.platform,
                "model": s.image_model,
                "out_path": str(artifact_path),
                "brand_name": req.brand_name,
                "industry": req.industry,
                "brand_color_hex": req.brand_color_hex,
                "main_text": req.main_text,
                "validators": {
                    "safezone_margin": s.safezone_margin,
                    "safezone_busyness_threshold": s.safezone_busyness_threshold,
                    "enable_ocr": s.enable_ocr,
                    "ocr_confidence": s.ocr_confidence,
                    "ocr_require_text": s.ocr_require_text,
                    "ocr_enforce_safezone": s.ocr_enforce_safezone,
                },
                "warnings": warnings,
            }

            log_event(s.log_dir, event)

            if verdict.status == "PASS":
                return event

            last_fail_reason = verdict.reason

        except Exception as e:
            last_fail_reason = f"EXCEPTION:{type(e).__name__}"
            log_event(s.log_dir, {
                "status": "FAIL",
                "reason": last_fail_reason,
                "attempt": attempts,
                "platform": req.platform,
                "model": s.image_model,
                "error": str(e),
            })

    return {
        "status": "FAIL",
        "reason": last_fail_reason or "UNKNOWN",
        "attempt": attempts,
        "platform": req.platform,
        "out_path": last_artifact_path,
    }


def main():
    load_dotenv()
    st.set_page_config(page_title="Titan-Social v0", layout="wide")

    st.title("Titan-Social v0 — Lane 1 (Boring, Correct Graphics)")
    st.caption("Generate → Validate → Deliver. No surprises. Strict PASS/FAIL.")

    try:
        s = Settings.from_env()
    except Exception as e:
        st.error(f"Config error: {e}")
        st.stop()

    ensure_dirs(s.out_dir, s.log_dir)

    with st.sidebar:
        st.header("Inputs (Strict Contract)")
        brand_name = st.text_input("Brand Name", value="AOGRL Deliveries")
        industry = st.text_input("Industry", value="Delivery & Logistics")
        brand_color_hex = st.text_input("Brand Color Hex", value="#FF2D55")

        platform = st.selectbox(
            "Platform",
            ["IG_FEED", "IG_STORY", "LINKEDIN", "FB_FEED", "X"],
            index=0
        )

        main_text = st.text_input("Main Text", value="FAST SAME DAY")

        st.divider()
        st.subheader("Lane-1 Settings (Read-only feel)")
        st.write(f"Model: `{s.image_model}`")
        st.write(f"Safe-zone margin: `{s.safezone_margin}`")
        st.write(f"OCR enabled: `{s.enable_ocr}` (Warnings if Tesseract missing)")
        st.write(f"Outputs: `{s.out_dir}`")
        st.write(f"Logs: `{s.log_dir}`")

        go = st.button("Generate Graphic ✅", use_container_width=True)

    colA, colB = st.columns([1.2, 1.0])

    with colA:
        st.subheader("Latest Result")
        if go:
            if s.provider_type == "openai" and (not s.openai_api_key or "dummy" in s.openai_api_key.lower()):
                 st.error("OPENAI_API_KEY looks missing/dummy. Add your real key in .env or remove it to use Local Mode.")
                 st.stop()

            req = GraphicRequest(
                brand_name=brand_name.strip(),
                industry=industry.strip(),
                brand_color_hex=brand_color_hex.strip(),
                platform=platform,
                main_text=main_text.strip(),
            )

            with st.spinner("Generating + validating..."):
                event = run_one(req, s)

            st.success(f"STATUS: {event.get('status')} | REASON: {event.get('reason')}")
            if event.get("warnings"):
                st.warning("Warnings:\n- " + "\n- ".join(event["warnings"]))

            out_path = event.get("out_path")
            if out_path and Path(out_path).exists():
                st.image(str(out_path), caption=Path(out_path).name, use_container_width=True)

            st.code(json.dumps(event, indent=2), language="json")

        else:
            st.info("Fill inputs on the left → click **Generate Graphic**.")

    with colB:
        st.subheader("Recent Runs (Last 50)")
        events = load_recent_events(s.log_dir, n=50)
        if not events:
            st.write("No logs yet.")
        else:
            for e in events[:20]:
                status = e.get("status", "?")
                reason = e.get("reason", "")
                ts = e.get("ts", "")
                plat = e.get("platform", "")
                path = e.get("out_path", "")

                with st.expander(f"{status} | {plat} | {reason} | {ts}"):
                    st.write("Text:", e.get("main_text", ""))
                    if e.get("warnings"):
                        st.warning("Warnings:\n- " + "\n- ".join(e["warnings"]))
                    if path and Path(path).exists():
                        st.image(path, use_container_width=True)
                    st.code(json.dumps(e, indent=2), language="json")


if __name__ == "__main__":
    main()
