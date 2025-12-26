import json
from pathlib import Path
from dotenv import load_dotenv

from titan_social.config import Settings
from titan_social.types import GraphicRequest
from titan_social.dispatcher import dispatch_platform
from titan_social.prompt import build_locked_prompt
from titan_social.provider_openai import OpenAIImageProvider
from titan_social.provider_hf import HFImageProvider
from titan_social.provider_local import LocalTemplateProvider
from titan_social.provider_replicate import ReplicateImageProvider
from titan_social.validators import validate_lane1_image
from titan_social.logging_utils import (
    ensure_dirs,
    log_event,
    should_trip_kill_switch,
    KillSwitchTripped,
)

MAX_ATTEMPTS = 2


def main():
    load_dotenv()
    s = Settings.from_env()
    ensure_dirs(s.out_dir, s.log_dir)

    req = GraphicRequest(
        brand_name="AOGRL Deliveries",
        industry="Delivery & Logistics",
        brand_color_hex="#FF2D55",
        platform="IG_FEED",
        main_text="FAST SAME DAY",
    )

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

            artifact_name = f"{req.platform}_{req.brand_name.replace(' ', '_')}_{attempts}.png"
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
                print(json.dumps(event, indent=2))
                break

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

        if should_trip_kill_switch(
            log_dir=s.log_dir,
            window=s.fail_rate_window,
            threshold=s.fail_rate_threshold
        ):
            raise KillSwitchTripped(
                f"Kill-switch tripped (FAIL rate > {s.fail_rate_threshold:.0%} over last {s.fail_rate_window})."
            )

    else:
        print(json.dumps({
            "status": "FAIL",
            "reason": last_fail_reason or "UNKNOWN",
            "attempts": MAX_ATTEMPTS,
            "last_artifact_path": last_artifact_path
        }, indent=2))


if __name__ == "__main__":
    main()
