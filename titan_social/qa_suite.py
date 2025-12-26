"""
Quality Assurance Test Suite for Titan-Social
Generates test images across all platforms and text lengths
"""
import json
from pathlib import Path
from dotenv import load_dotenv

from titan_social.config import Settings
from titan_social.types import GraphicRequest
from titan_social.dispatcher import dispatch_platform
from titan_social.prompt import build_locked_prompt
from titan_social.provider_local import LocalTemplateProvider
from titan_social.logging_utils import ensure_dirs
from titan_social.validators import validate_lane1_image

def run_qa_suite():
    load_dotenv()
    s = Settings.from_env()
    ensure_dirs(s.out_dir, s.log_dir)
    
    provider = LocalTemplateProvider()
    
    # Test matrix
    tests = [
        # Platform, Text, Expected Layout
        ("IG_FEED", "FAST SAME DAY", "badge"),
        ("IG_FEED", "Get 25% off your first order today", "badge"),
        ("IG_STORY", "NEW COLLECTION DROPS FRIDAY", "hero"),
        ("IG_STORY", "Limited time offer - Free shipping on all orders over $50", "hero"),
        ("LINKEDIN", "PROFESSIONAL SERVICES", "badge"),
        ("LINKEDIN", "Transform your business with our expert consulting team", "badge"),
        ("FB_FEED", "SUMMER SALE NOW ON", "split"),
        ("X", "BREAKING NEWS", "badge"),
    ]
    
    results = []
    
    for platform, text, expected_layout in tests:
        req = GraphicRequest(
            brand_name="QA Test",
            industry="Quality Assurance",
            brand_color_hex="#FF2D55",
            platform=platform,
            main_text=text,
        )
        
        dispatch = dispatch_platform(req.platform)
        prompt = build_locked_prompt(
            industry=req.industry,
            main_text=req.main_text,
            brand_color_hex=req.brand_color_hex,
            platform=req.platform,
        )
        
        # Generate
        img_bytes = provider.generate_png(
            prompt=prompt,
            width=dispatch.width,
            height=dispatch.height,
        )
        
        # Save
        safe_text = text.replace(' ', '_')[:30]
        artifact_name = f"QA_{platform}_{safe_text}.png"
        artifact_path = Path(s.out_dir) / artifact_name
        artifact_path.write_bytes(img_bytes)
        
        # Validate
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
        
        result = {
            "platform": platform,
            "text": text,
            "expected_layout": expected_layout,
            "status": verdict.status,
            "reason": verdict.reason,
            "warnings": warnings,
            "path": str(artifact_path),
        }
        
        results.append(result)
        
        status_icon = "✅" if verdict.status == "PASS" else "❌"
        print(f"{status_icon} {platform:12} | {verdict.status:4} | {text[:40]}")
    
    # Summary
    passed = sum(1 for r in results if r["status"] == "PASS")
    total = len(results)
    
    print(f"\n{'='*60}")
    print(f"QA RESULTS: {passed}/{total} PASSED ({passed/total*100:.0f}%)")
    print(f"{'='*60}")
    print(f"\nImages saved to: {s.out_dir}")
    
    # Save report
    report_path = Path(s.out_dir) / "qa_report.json"
    report_path.write_text(json.dumps(results, indent=2))
    print(f"Report saved to: {report_path}")
    
    return results

if __name__ == "__main__":
    run_qa_suite()
