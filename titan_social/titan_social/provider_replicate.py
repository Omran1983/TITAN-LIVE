import replicate
import io
import time
from PIL import Image

class ReplicateImageProvider:
    def __init__(self, *, api_key: str, model: str = "stability-ai/sdxl:7762fd07cf82c948538e41f63f77d685e022b063e37e496e96eefd46c929f9bdc"):
        self.api_key = api_key
        self.model = model
        self.client = replicate.Client(api_token=api_key)

    def generate_png(self, *, prompt: str, width: int, height: int) -> bytes:
        """Generate image using Replicate SDXL with intelligent retry"""
        
        max_retries = 5
        base_delay = 15  # Start with 15 seconds
        
        for attempt in range(max_retries):
            try:
                # Run SDXL using client
                output = self.client.run(
                    self.model,
                    input={
                        "prompt": prompt,
                        "width": width,
                        "height": height,
                        "num_outputs": 1,
                        "negative_prompt": "text, words, letters, watermark, blurry, low quality, distorted",
                    }
                )
                
                # Output is a list of URLs or FileOutput objects
                if not output:
                    raise RuntimeError("Replicate returned no images")
                
                # Get first output
                image_output = output[0] if isinstance(output, list) else output
                
                # If it's a FileOutput, get the URL
                if hasattr(image_output, 'url'):
                    image_url = image_output.url
                else:
                    image_url = str(image_output)
                
                # Download image
                import requests
                response = requests.get(image_url, timeout=30)
                
                if response.status_code != 200:
                    raise RuntimeError(f"Failed to download image: {response.status_code}")
                
                return response.content
                
            except Exception as e:
                error_str = str(e)
                
                # Check if it's a 429 rate limit error
                if "429" in error_str or "throttled" in error_str.lower() or "rate limit" in error_str.lower():
                    if attempt < max_retries - 1:
                        # Exponential backoff: 15s, 30s, 60s, 120s
                        delay = base_delay * (2 ** attempt)
                        print(f"Rate limited. Waiting {delay}s before retry {attempt + 1}/{max_retries}...")
                        time.sleep(delay)
                        continue
                
                # If not rate limit, or final attempt, raise the error
                raise
        
        raise RuntimeError(f"Failed after {max_retries} retries due to rate limiting")
