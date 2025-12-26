from PIL import Image
import numpy as np
from math import gcd
from typing import Tuple, List, Optional, Dict, Any

from titan_social.types import ValidationVerdict


def _hex_to_rgb(hex_color: str) -> Tuple[int, int, int]:
    h = hex_color.strip().lstrip("#")
    if len(h) != 6:
        raise ValueError("brand_color_hex must be #RRGGBB")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def _aspect_ratio_str(w: int, h: int) -> str:
    g = gcd(w, h)
    return f"{w // g}:{h // g}"


def _brand_color_presence(img_rgb: np.ndarray, brand_rgb: Tuple[int, int, int], tol: int = 45) -> float:
    r, g, b = brand_rgb
    diff = np.sqrt(
        (img_rgb[..., 0] - r) ** 2 +
        (img_rgb[..., 1] - g) ** 2 +
        (img_rgb[..., 2] - b) ** 2
    )
    return float(np.mean(diff <= tol))


def _edge_density_proxy(img_gray: np.ndarray) -> float:
    gx = np.abs(np.diff(img_gray, axis=1))
    gy = np.abs(np.diff(img_gray, axis=0))
    gx = np.pad(gx, ((0, 0), (0, 1)), mode="edge")
    gy = np.pad(gy, ((0, 1), (0, 0)), mode="edge")
    grad = gx + gy
    return float(np.mean(grad) / 255.0)


def _safezone_slices(w: int, h: int, margin_frac: float):
    mx = max(1, int(w * margin_frac))
    my = max(1, int(h * margin_frac))

    # margins: top, bottom, left, right
    top = (slice(0, my), slice(0, w))
    bottom = (slice(h - my, h), slice(0, w))
    left = (slice(0, h), slice(0, mx))
    right = (slice(0, h), slice(w - mx, w))

    # inner safe area bounds
    safe_x0, safe_y0 = mx, my
    safe_x1, safe_y1 = w - mx, h - my
    return (top, bottom, left, right), (safe_x0, safe_y0, safe_x1, safe_y1)


def _margin_busyness_fail(gray: np.ndarray, margin_frac: float, busyness_threshold: float) -> bool:
    h, w = gray.shape
    margin_slices, _ = _safezone_slices(w, h, margin_frac)

    busyness_vals = []
    for sl_y, sl_x in margin_slices:
        region = gray[sl_y, sl_x]
        busyness_vals.append(_edge_density_proxy(region))

    return any(b > busyness_threshold for b in busyness_vals)


# ---------------- OCR (optional) ----------------

def _try_import_ocr():
    try:
        import pytesseract  # type: ignore
        return pytesseract
    except Exception:
        return None


def _ocr_words_with_boxes(image: Image.Image) -> Tuple[Optional[str], List[dict]]:
    pytesseract = _try_import_ocr()
    if pytesseract is None:
        return ("OCR_UNAVAILABLE:pytesseract_not_installed", [])

    try:
        data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)
    except Exception as e:
        return (f"OCR_UNAVAILABLE:{type(e).__name__}", [])

    words = []
    n = len(data.get("text", []))
    for i in range(n):
        txt = (data["text"][i] or "").strip()
        if not txt:
            continue
        try:
            conf = int(float(data["conf"][i]))
        except Exception:
            conf = -1

        words.append({
            "text": txt,
            "conf": conf,
            "x": int(data["left"][i]),
            "y": int(data["top"][i]),
            "w": int(data["width"][i]),
            "h": int(data["height"][i]),
        })

    return (None, words)


def _ocr_readability_check(
    *,
    image: Image.Image,
    min_conf: int,
    require_text: bool,
) -> Tuple[bool, str]:
    err, words = _ocr_words_with_boxes(image)
    if err is not None:
        return (True, err)  # graceful

    good = [w for w in words if w["conf"] >= min_conf]

    if require_text and len(good) == 0:
        return (False, "TEXT_UNREADABLE_OR_MISSING")

    return (True, "OK")


def _ocr_safezone_check(
    *,
    image: Image.Image,
    min_conf: int,
    margin_frac: float,
) -> Tuple[bool, str]:
    err, words = _ocr_words_with_boxes(image)
    if err is not None:
        return (True, err)  # graceful

    w, h = image.size
    _, (sx0, sy0, sx1, sy1) = _safezone_slices(w, h, margin_frac)

    good = [wrd for wrd in words if wrd["conf"] >= min_conf]
    for wrd in good:
        x0, y0 = wrd["x"], wrd["y"]
        x1, y1 = wrd["x"] + wrd["w"], wrd["y"] + wrd["h"]

        if x0 < sx0 or y0 < sy0 or x1 > sx1 or y1 > sy1:
            return (False, "SAFEZONE_TEXT_TOUCHING_EDGE")

    return (True, "OK")


# ---------------- Lane 1 Validator ----------------

def validate_lane1_image(
    *,
    image_path: str,
    expected_width: int,
    expected_height: int,
    expected_aspect_ratio: str,
    brand_color_hex: str,
    safezone_margin: float,
    safezone_busyness_threshold: float,
    enable_ocr: bool,
    ocr_confidence: int,
    ocr_require_text: bool,
    ocr_enforce_safezone: bool,
) -> Tuple[ValidationVerdict, List[str]]:
    """
    Returns (verdict, warnings[])
    warnings contains OCR infra warnings like OCR_UNAVAILABLE:...
    """
    warnings: List[str] = []

    im = Image.open(image_path).convert("RGB")
    w, h = im.size

    if (w, h) != (expected_width, expected_height):
        return ValidationVerdict("FAIL", "WRONG_DIMENSIONS"), warnings

    ar = _aspect_ratio_str(w, h)
    if ar != expected_aspect_ratio:
        return ValidationVerdict("FAIL", "WRONG_ASPECT_RATIO"), warnings

    arr = np.asarray(im).astype(np.float32)
    gray = np.asarray(im.convert("L")).astype(np.float32)

    brand_rgb = _hex_to_rgb(brand_color_hex)
    presence = _brand_color_presence(arr, brand_rgb, tol=45)
    if presence < 0.02:
        return ValidationVerdict("FAIL", "OFF_BRAND_COLOR_MISSING"), warnings

    busyness = _edge_density_proxy(gray)
    if busyness > 0.22:
        return ValidationVerdict("FAIL", "TOO_CLUTTERED"), warnings

    if _margin_busyness_fail(gray, safezone_margin, safezone_busyness_threshold):
        return ValidationVerdict("FAIL", "SAFEZONE_VIOLATION_MARGIN_BUSY"), warnings

    if enable_ocr:
        ok_read, reason_read = _ocr_readability_check(
            image=im,
            min_conf=ocr_confidence,
            require_text=ocr_require_text,
        )
        if reason_read.startswith("OCR_UNAVAILABLE:"):
            warnings.append(reason_read)
        if not ok_read:
            return ValidationVerdict("FAIL", reason_read), warnings

        if ocr_enforce_safezone:
            ok_sz, reason_sz = _ocr_safezone_check(
                image=im,
                min_conf=ocr_confidence,
                margin_frac=safezone_margin,
            )
            if reason_sz.startswith("OCR_UNAVAILABLE:"):
                warnings.append(reason_sz)
            if not ok_sz:
                return ValidationVerdict("FAIL", reason_sz), warnings

    return ValidationVerdict("PASS", "OK"), warnings
