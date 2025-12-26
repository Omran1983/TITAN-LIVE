from pathlib import Path
from datetime import datetime

import mss
from PIL import Image
import pytesseract

BASE_DIR = Path(__file__).resolve().parent.parent
SCREENSHOT_DIR = BASE_DIR / "screenshots"

def capture_screen():
    SCREENSHOT_DIR.mkdir(exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_path = SCREENSHOT_DIR / f"screen_{ts}.png"

    with mss.mss() as sct:
        sct.shot(mon=1, output=str(out_path))

    print(f"[vision] Screenshot saved to {out_path}")
    return out_path

def ocr_image(image_path: Path) -> str:
    img = Image.open(image_path)
    text = pytesseract.image_to_string(img)
    print(f"[vision] OCR extracted {len(text)} characters")
    return text

if __name__ == "__main__":
    p = capture_screen()
    _ = ocr_image(p)
