"""
JARVIS VISION (PHASE 14)
------------------------
The "Eyes" of AION-ZERO.
Uses a local Multimodal AI (Llama-Vision or Llava) to analyze images.

CAPABILITIES:
1.  Screenshot: Captures the primary display.
2.  Analyze: Sends image + prompt to Ollama.
3.  Report: Returns a description or critique of what it sees.
"""

import os
import sys
import base64
import requests
import argparse
from io import BytesIO
from datetime import datetime
from PIL import Image, ImageGrab

# --- CONFIG ---
# Default to "llava" (best open source vision model for Ollama)
VISION_MODEL = os.environ.get("AZ_VISION_MODEL", "llava") 
OLLAMA_URL = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434")

def capture_screen():
    """Captures the screen and returns PIL Image."""
    print("[VISION] Capturing visual cortex input...")
    return ImageGrab.grab()

def encode_image(image):
    """Encodes PIL Image to Base64 string."""
    buffered = BytesIO()
    image.save(buffered, format="JPEG")
    return base64.b64encode(buffered.getvalue()).decode("utf-8")

def analyze_image(image, prompt):
    """Sends image to Ollama for analysis."""
    print(f"[VISION] Analyzing with model '{VISION_MODEL}'...")
    
    b64_img = encode_image(image)
    
    payload = {
        "model": VISION_MODEL,
        "prompt": prompt,
        "images": [b64_img],
        "stream": False
    }
    
    try:
        start = datetime.now()
        r = requests.post(f"{OLLAMA_URL}/api/generate", json=payload, timeout=120)
        r.raise_for_status()
        duration = (datetime.now() - start).total_seconds()
        
        response_text = r.json()["response"]
        print(f"[VISION] Analysis complete ({duration:.1f}s).")
        return response_text
    except Exception as e:
        return f"[ERROR] Blindness detected: {e}"

def main():
    parser = argparse.ArgumentParser(description="AION-ZERO Vision Module")
    parser.add_argument("--prompt", type=str, default="Describe what you see in technical detail.", help="What to ask the eye.")
    parser.add_argument("--save", action="store_true", help="Save the screenshot to debug.")
    parser.add_argument("--loop", action="store_true", help="Continuously capture for live Citadel feed.")
    args = parser.parse_args()

    def loop_once():
        # 1. See
        img = capture_screen()

        # Always save latest for Citadel UI
        try:
            log_dir = r"F:\AION-ZERO\logs"
            if not os.path.exists(log_dir):
                os.makedirs(log_dir)
            live_feed_path = os.path.join(log_dir, "latest_vision.jpg")
            img.save(live_feed_path, quality=50)  # Low quality for speed
        except Exception as e:
            print(f"[VISION] UI Feed Error: {e}")

        if args.save:
            ts = datetime.now().strftime("%Y%m%d_%H%M%S")
            path = f"F:\\AION-ZERO\\logs\\vision_capture_{ts}.jpg"
            img.save(path)
            print(f"[VISION] Saved retina dump to {path}")

        # 2. Think
        result = analyze_image(img, args.prompt)

        # 3. Report
        print("\n--- VISUAL INSIGHT ---")
        print(result)
        print("----------------------")

    if args.loop:
        print("[VISION] Loop mode enabled. Press Ctrl+C to stop.")
        try:
            while True:
                loop_once()
                # You can adjust sleep for smoother vs lighter loop
                import time
                time.sleep(2)
        except KeyboardInterrupt:
            print("[VISION] Loop stopped by user.")
    else:
        loop_once()

if __name__ == "__main__":
    main()
