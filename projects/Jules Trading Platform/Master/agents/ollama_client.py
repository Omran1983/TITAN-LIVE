import requests
import json
from logging_config import log

class OllamaClient:
    """
    Client for interacting with local Ollama instance.
    Defaults to 'llama3.2' model.
    """
    def __init__(self, base_url="http://localhost:11434", model="llama3.2:1b"):
        self.base_url = base_url
        self.model = model
        log.info(f"Ollama Client initialized. Target: {base_url} Model: {model}")

    def generate(self, prompt: str, system_prompt: str = "") -> str:
        """
        Generates text completion using the local LLM.
        """
        url = f"{self.base_url}/api/generate"
        
        full_prompt = f"System: {system_prompt}\nUser: {prompt}" if system_prompt else prompt
        
        payload = {
            "model": self.model,
            "prompt": full_prompt,
            "stream": False,
            "options": {
                "temperature": 0.1, # Low temp for factual analysis
                "seed": 42
            }
        }
        
        try:
            response = requests.post(url, json=payload, timeout=30)
            response.raise_for_status()
            data = response.json()
            return data.get("response", "").strip()
        except requests.exceptions.RequestException as e:
            log.error(f"Ollama API Error: {e}")
            return "ERROR"

if __name__ == "__main__":
    # Test
    client = OllamaClient()
    print(client.generate("Say 'Hello Pilot' if you are online.", system_prompt="You are a trading bot."))
