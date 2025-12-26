import requests
import io
from typing import Optional

class HFImageProvider:
    def __init__(self, *, api_key: str, model: str = "black-forest-labs/FLUX.1-schnell"):
        self.api_key = api_key
        self.model = model
        # Use Inference API
        self.api_url = f"https://api-inference.huggingface.co/models/{model}"
        self.headers = {"Authorization": f"Bearer {api_key}"}

    def generate_png(self, *, prompt: str, width: int, height: int) -> bytes:
        # Simplified payload for Flux
        payload = {
            "inputs": prompt,
        }
        
        # HF models can take 20-30s to load first time
        response = requests.post(self.api_url, headers=self.headers, json=payload, timeout=60)
        
        if response.status_code == 503:
            # Model is loading, wait and retry
            import time
            print("Model loading, waiting 20s...")
            time.sleep(20)
            response = requests.post(self.api_url, headers=self.headers, json=payload, timeout=60)
        
        if response.status_code != 200:
            error_msg = f"HF Error {response.status_code}: {response.text[:500]}"
            raise RuntimeError(error_msg)
            
        # Response is image bytes
        return response.content
