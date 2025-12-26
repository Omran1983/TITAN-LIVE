from PIL import Image, ImageDraw
import io

class MockImageProvider:
    def __init__(self, *, api_key: str, model: str):
        self.model = model

    def generate_png(self, *, prompt: str, width: int, height: int) -> bytes:
        img = Image.new('RGB', (width, height), color='#FF0000') # Wrong color to trigger fail? Or Pass? 
        # User wants to tune thresholds. Let's return a "Good" image (Brand color #FF2D55).
        # Request uses #FF2D55.
        img = Image.new('RGB', (width, height), color='#FF2D55')
        
        d = ImageDraw.Draw(img)
        d.text((width//2, height//2), "MOCK IMAGE", fill=(255, 255, 255))
        
        buf = io.BytesIO()
        img.save(buf, format='PNG')
        return buf.getvalue()
