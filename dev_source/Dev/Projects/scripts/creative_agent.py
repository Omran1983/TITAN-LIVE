# creative_agent.py
# FastAPI service that 1) creates a copy plan via Ollama, 2) renders images via ComfyUI.
# Tested with Python 3.13, FastAPI, Requests, Uvicorn.

import os
import re
import json
import time
import uuid
import glob
from typing import Optional, Dict, Any, List

import requests
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

# ------------ Environment & Defaults ------------
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "phi3:mini")
OLLAMA_MODEL_FALLBACK = os.environ.get("OLLAMA_MODEL_FALLBACK", "phi3:mini")

IMAGE_PROVIDER = os.environ.get("IMAGE_PROVIDER", "comfyui")  # expect 'comfyui'
COMFY_URL = os.environ.get("COMFYUI_URL", "http://127.0.0.1:8188")
COMFY_ROOT = os.environ.get("COMFYUI_ROOT", "C:/ComfyUI")
# IMPORTANT: this must match exactly what ComfyUI lists under CheckpointLoaderSimple
COMFY_CKPT = os.environ.get("COMFY_CKPT", r"SD1.5\AOM3A1_orangemixs.safetensors")

# ------------ App ------------
app = FastAPI(title="Creative Agent - Plan + Images (v3)", version="0.1.0")


# ------------ Models ------------
class Job(BaseModel):
    product_name: str = Field(..., alias="product_name")
    angle: str = Field(default="Restock & Scarcity")
    locale: str = Field(default="EN-MU")
    price_rs: Optional[int] = None
    n_images: int = Field(default=2, ge=1, le=8)

    class Config:
        populate_by_name = True


# ------------ Helpers ------------
def _strip_code_fences(s: str) -> str:
    s = s.strip()
    # remove ```json ... ``` fences or plain ```
    s = re.sub(r"^```(?:json)?\s*", "", s, flags=re.IGNORECASE)
    s = re.sub(r"\s*```$", "", s)
    return s.strip()


def _force_json(text: str) -> Dict[str, Any]:
    """
    Try very hard to coerce a language model response into valid JSON.
    """
    if not text:
        raise ValueError("Empty model response")

    s = _strip_code_fences(text)

    # take the biggest {...} block
    start = s.find("{")
    end = s.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise ValueError("No JSON object found in model response")

    candidate = s[start : end + 1]

    # attempt 1: as-is
    try:
        return json.loads(candidate)
    except Exception:
        pass

    # attempt 2: swap single quotes to double
    cand2 = candidate.replace("'", '"')
    try:
        return json.loads(cand2)
    except Exception:
        pass

    # attempt 3: remove trailing commas
    cand3 = re.sub(r",\s*([}\]])", r"\1", cand2)
    try:
        return json.loads(cand3)
    except Exception as e:
        raise ValueError(f"Could not parse JSON from model: {e}")  # bubble up


def _ollama_json(prompt: str) -> Dict[str, Any]:
    """
    Ask Ollama for JSON and parse it robustly. Falls back to OLLAMA_MODEL_FALLBACK if needed.
    """
    models: List[str] = (
        [OLLAMA_MODEL]
        if OLLAMA_MODEL == OLLAMA_MODEL_FALLBACK
        else [OLLAMA_MODEL, OLLAMA_MODEL_FALLBACK]
    )

    last_err = None
    for m in models:
        try:
            body = {
                "model": m,
                "prompt": prompt,
                "stream": False,
                "options": {"num_ctx": 4096},
            }
            r = requests.post(f"{OLLAMA_URL}/api/generate", json=body, timeout=180)
            r.raise_for_status()
            resp_text = r.json().get("response", "")
            return _force_json(resp_text)
        except Exception as e:
            last_err = e
            continue

    raise HTTPException(status_code=500, detail=f"Ollama failed: {last_err}")


def _build_plan_prompt(product: str, angle: str, locale: str, price: Optional[int]) -> str:
    """
    Plain text instructions. No .format or f-string braces to avoid formatting errors.
    We ask for strict JSON keys we expect in the app.
    """
    price_str = "unknown" if price is None else str(price)
    lines = [
        "You are a direct-response copywriter. Create a short social promo plan.",
        f"Product: {product}",
        f"Angle: {angle}",
        f"Locale: {locale}",
        f"Price_RS: {price_str}",
        "",
        "Return STRICT JSON ONLY with this exact shape:",
        "{",
        '  "hooks": [ "string", "string", "string" ],',
        '  "captions": { "short": "string", "standard": "string", "long": "string" },',
        '  "alt_text": "string"',
        "}",
        "",
        "No prose. No markdown. JSON only.",
    ]
    return "\n".join(lines)


def _comfy_prompt_payload(ckpt_name: str, pos_text: str, filename_prefix: str) -> Dict[str, Any]:
    """
    Minimal SD1.5 txt2img workflow that worked on your box.
    640x640, Euler, 14 steps, with filename_prefix for SaveImage.
    """
    return {
        "client_id": "creative-agent",
        "prompt": {
            "3": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": ckpt_name}},
            "4": {
                "class_type": "CLIPTextEncode",
                "inputs": {"text": pos_text, "clip": ["3", 1]},
            },
            "5": {
                "class_type": "CLIPTextEncode",
                "inputs": {"text": "blurry, low-res, watermark, text, logo", "clip": ["3", 1]},
            },
            "6": {
                "class_type": "EmptyLatentImage",
                "inputs": {"width": 640, "height": 640, "batch_size": 1},
            },
            "7": {
                "class_type": "KSampler",
                "inputs": {
                    "model": ["3", 0],
                    "positive": ["4", 0],
                    "negative": ["5", 0],
                    "latent_image": ["6", 0],
                    "seed": 1234567,
                    "steps": 14,
                    "cfg": 5,
                    "sampler_name": "euler",
                    "scheduler": "normal",
                    "denoise": 1.0,
                },
            },
            "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["3", 2]}},
            "9": {
                "class_type": "SaveImage",
                "inputs": {"images": ["8", 0], "filename_prefix": filename_prefix},
            },
        },
    }


def _wait_for_images(prefix: str, timeout_s: int = 180) -> List[str]:
    """
    Poll C:/ComfyUI/output for files that start with prefix and end with .png
    """
    out_dir = os.path.join(COMFY_ROOT, "output").replace("/", "\\")
    want_glob = os.path.join(out_dir, f"{prefix}*.png")
    seen: set[str] = set(glob.glob(want_glob))
    t0 = time.time()
    while time.time() - t0 < timeout_s:
        paths = glob.glob(want_glob)
        new_paths = [p for p in paths if p not in seen]
        if new_paths:
            return sorted(new_paths, key=os.path.getmtime, reverse=True)
        time.sleep(1.0)
    # if we get here, return whatever exists (maybe Comfy already wrote something earlier)
    return sorted(glob.glob(want_glob), key=os.path.getmtime, reverse=True)


# ------------ Routes ------------
@app.get("/health")
def health():
    return {
        "status": "ok",
        "primary_model": OLLAMA_MODEL,
        "fallback_model": OLLAMA_MODEL_FALLBACK,
        "ollama": OLLAMA_URL,
        "image_provider": IMAGE_PROVIDER,
    }


@app.get("/mock_plan")
def mock_plan():
    creative_id = uuid.uuid4().hex
    plan = {
        "hooks": [
            "Back in stock: Brush Set sells out fast!",
            "Level-up your blend — fresh restock!",
            "Last chance before they vanish (again).",
        ],
        "captions": {
            "short": "Restocked. Softer, denser, better blends. ₹1490.",
            "standard": "Our best-selling Brush Set is back. Silky bristles for seamless blend & control — now in stock at ₹1490. Grab yours before it’s gone.",
            "long": "You asked, we restocked. This Brush Set delivers soft, even application with zero scratch. Perfect for precise placement and effortless blending. Limited quantities — ₹1490 while it lasts.",
        },
        "alt_text": "Neutral product photo of a premium makeup brush set with soft studio lighting.",
    }
    return {"creative_id": creative_id, "plan": plan}


@app.post("/generate_plan")
def generate_plan(job: Job):
    creative_id = uuid.uuid4().hex

    user_prompt = _build_plan_prompt(
        product=job.product_name,
        angle=job.angle,
        locale=job.locale,
        price=job.price_rs,
    )

    try:
        plan_json = _ollama_json(user_prompt)
    except Exception as e:
        # fall back to a minimal safe plan so the caller never gets stuck
        plan_json = {
            "hooks": [f"New {job.product_name} drop.", "Restocked today.", "Don’t miss it."],
            "captions": {
                "short": f"{job.product_name} — available now.",
                "standard": f"{job.product_name} is back in stock. Grab yours while it lasts.",
                "long": f"{job.product_name} returns. Limited quantity. Order now to avoid missing out.",
            },
            "alt_text": f"Clean studio photo of {job.product_name} on neutral backdrop.",
        }

    # normalize keys we care about
    hooks = plan_json.get("hooks") or []
    captions = plan_json.get("captions") or {}
    alt_text = plan_json.get("alt_text") or ""

    # ensure required caption lengths exist
    for k in ("short", "standard", "long"):
        captions.setdefault(k, f"{job.product_name} — {k} caption.")

    return {"creative_id": creative_id, "plan": {"hooks": hooks, "captions": captions, "alt_text": alt_text}}


@app.post("/generate_images")
def generate_images(job: Job):
    if IMAGE_PROVIDER.lower() != "comfyui":
        raise HTTPException(status_code=500, detail="IMAGE_PROVIDER is not 'comfyui'.")

    # sanity checks
    if not COMFY_CKPT or "\\" not in COMFY_CKPT:
        raise HTTPException(
            status_code=500,
            detail=f"COMFY_CKPT looks wrong for Windows/ComfyUI list: '{COMFY_CKPT}'",
        )

    # build a single positive prompt string from the job
    base_prompt = (
        f"{job.product_name} on neutral backdrop, studio lighting, soft shadows, high detail, "
        f"premium product photography, clean composition, commercial e-commerce photo"
    )
    # optional angle hint
    if job.angle:
        base_prompt += f", angle: {job.angle}"

    results: List[str] = []
    creative_id = uuid.uuid4().hex
    prefix = f"agent_{creative_id}_"

    for i in range(job.n_images):
        payload = _comfy_prompt_payload(COMFY_CKPT, base_prompt, prefix)
        try:
            r = requests.post(f"{COMFY_URL}/prompt", json=payload, timeout=300)
            r.raise_for_status()
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"ComfyUI /prompt failed: {e}")

        # wait for images to appear
        paths = _wait_for_images(prefix, timeout_s=240)
        if not paths:
            raise HTTPException(status_code=504, detail="ComfyUI produced no files within timeout.")
        # collect newest for this round
        newest = paths[0]
        if newest not in results:
            results.append(newest)

    return {"creative_id": creative_id, "images": results, "used_checkpoint": COMFY_CKPT}
