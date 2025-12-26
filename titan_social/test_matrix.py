import json
import time
from pathlib import Path
from dotenv import load_dotenv

from titan_social.config import Settings
from titan_social.types import GraphicRequest
from titan_social.dispatcher import dispatch_platform
from titan_social.prompt import build_locked_prompt
from titan_social.provider_openai import OpenAIImageProvider
from titan_social.provider_hf import HFImageProvider
from titan_social.logging_utils import ensure_dirs, log_event
from titan_social.validators import validate_lane1_image

MAX_ATTEMPTS = 2


def run_one(req: GraphicRequest, s: Settings):
    dispatch = dispatch_platform(req.platform)
    prompt = build_locked_prompt(
        industry=req.industry,
        main_text=req.main_text,
        brand_color_hex=req.brand_color_hex,
        platform=req.platform,
    )
    
    if s.provider_type == "hf":
        provider = HFImageProvider(api_key=s.hf_token, model=s.image_model)
    else:
        provider = OpenAIImageProvider(api_key=s.openai_api_key, model=s.image_model)

    attempts = 0
    while attempts < MAX_ATTEMPTS:
        attempts += 1

        img_bytes = provider.generate_png(prompt=prompt, width=dispatch.width, height=dispatch.height)
        artifact_name = f"TEST_{req.platform}_{req.main_text.replace(' ', '_')}_{int(time.time())}_{attempts}.png"
        artifact_path = Path(s.out_dir) / artifact_name
        artifact_path.write_bytes(img_bytes)

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
            "warnings": warnings,
        }
        log_event(s.log_dir, event)

        if verdict.status == "PASS":
            return event

    return {"status": "FAIL", "reason": "EXHAUSTED", "platform": req.platform, "main_text": req.main_text}


def main():
    load_dotenv()
    s = Settings.from_env()
    ensure_dirs(s.out_dir, s.log_dir)

    tests = [
        ("IG_FEED", "FAST SAME DAY", "#FF2D55"),
        ("IG_STORY", "FAST SAME DAY", "#FF2D55"),
        ("LINKEDIN", "FAST SAME DAY", "#FF2D55"),
        ("IG_FEED", "DELIVERY IN 60 MINUTES", "#FF2D55"),
        ("IG_FEED", "ORDER TODAY CALL 5754 5715", "#FF2D55"),
        ("IG_FEED", "FAST SAME DAY", "#00B894"),
    ]

    results = []
    for platform, text, color in tests:
        req = GraphicRequest(
            brand_name="AOGRL Deliveries",
            industry="Delivery & Logistics",
            brand_color_hex=color,
            platform=platform,
            main_text=text,
        )
        r = run_one(req, s)
        results.append(r)
        print(r["status"], r.get("reason"), platform, text)

    print("\n=== SUMMARY ===")
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
