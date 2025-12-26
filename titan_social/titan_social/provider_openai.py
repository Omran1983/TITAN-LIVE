import base64
from openai import OpenAI


class OpenAIImageProvider:
    def __init__(self, *, api_key: str, model: str):
        self.client = OpenAI(api_key=api_key)
        self.model = model

    def generate_png(self, *, prompt: str, width: int, height: int) -> bytes:
        # OpenAI Images API uses size strings like "1024x1024".
        # We pass platform-native sizes directly.
        size = f"{width}x{height}"

        img = self.client.images.generate(
            model=self.model,
            prompt=prompt,
            n=1,
            size=size,
        )

        b64 = img.data[0].b64_json
        return base64.b64decode(b64)
