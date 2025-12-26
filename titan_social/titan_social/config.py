import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    openai_api_key: str
    hf_token: str
    replicate_token: str
    image_model: str
    provider_type: str  # "openai" or "hf" or "local" or "replicate"
    out_dir: str
    log_dir: str

    fail_rate_window: int
    fail_rate_threshold: float

    # Validators
    safezone_margin: float
    safezone_busyness_threshold: float

    enable_ocr: bool
    ocr_confidence: int
    ocr_require_text: bool
    ocr_enforce_safezone: bool

    @staticmethod
    def _get_bool(name: str, default: str) -> bool:
        v = os.getenv(name, default).strip().lower()
        return v in ("1", "true", "yes", "y", "on")

    @staticmethod
    def from_env() -> "Settings":
        openai_key = os.getenv("OPENAI_API_KEY", "").strip()
        hf_token = os.getenv("HF_TOKEN", "").strip()
        replicate_token = os.getenv("REPLICATE_API_TOKEN", "").strip()
        
        # Auto-detect provider
        if replicate_token:
            provider = "replicate"
            model = os.getenv("TITAN_IMAGE_MODEL", "stability-ai/sdxl").strip()
        elif hf_token:
            provider = "hf"
            model = os.getenv("TITAN_IMAGE_MODEL", "stabilityai/stable-diffusion-xl-base-1.0").strip()
        elif openai_key:
            provider = "openai"
            model = os.getenv("TITAN_IMAGE_MODEL", "gpt-image-1.5").strip()
        else:
            # Fallback for free mode
            provider = "local"
            model = "template-v1"

        out_dir = os.getenv("TITAN_SOCIAL_OUT_DIR", r"F:\AION-ZERO\outputs\titan-social")

        log_dir = os.getenv("TITAN_SOCIAL_LOG_DIR", r"F:\AION-ZERO\logs\titan-social")

        window = int(os.getenv("TITAN_FAIL_RATE_WINDOW", "20"))
        threshold = float(os.getenv("TITAN_FAIL_RATE_THRESHOLD", "0.30"))

        safezone_margin = float(os.getenv("TITAN_SAFEZONE_MARGIN", "0.08"))
        safezone_busyness_threshold = float(os.getenv("TITAN_SAFEZONE_BUSINESS_THRESHOLD", "0.20"))

        enable_ocr = Settings._get_bool("TITAN_ENABLE_OCR", "1")
        ocr_confidence = int(os.getenv("TITAN_OCR_CONFIDENCE", "55"))
        ocr_require_text = Settings._get_bool("TITAN_OCR_REQUIRE_TEXT", "1")
        ocr_enforce_safezone = Settings._get_bool("TITAN_OCR_ENFORCE_SAFEZONE", "1")

        if not (0.0 <= safezone_margin <= 0.25):
            raise RuntimeError("TITAN_SAFEZONE_MARGIN must be between 0.0 and 0.25")
        if not (0 <= ocr_confidence <= 100):
            raise RuntimeError("TITAN_OCR_CONFIDENCE must be between 0 and 100")

        return Settings(
            openai_api_key=openai_key,
            hf_token=hf_token,
            replicate_token=replicate_token,
            image_model=model,
            provider_type=provider,
            out_dir=out_dir,
            log_dir=log_dir,
            fail_rate_window=window,
            fail_rate_threshold=threshold,
            safezone_margin=safezone_margin,
            safezone_busyness_threshold=safezone_busyness_threshold,
            enable_ocr=enable_ocr,
            ocr_confidence=ocr_confidence,
            ocr_require_text=ocr_require_text,
            ocr_enforce_safezone=ocr_enforce_safezone,
        )
