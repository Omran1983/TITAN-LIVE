"""
JARVIS CHAT (INTERACTIVE MODE)
------------------------------
Stateful conversation with AION-ZERO.
Integrates:
1.  Ollama (Brain)
2.  Jarvis-Voice (Mouth)
"""

import os
import sys
import json
import requests
import subprocess
from datetime import datetime

# --- CONFIG ---
OLLAMA_URL = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434")
MODEL_NAME = os.environ.get("AZ_LOCAL_MODEL", "llama3")
VOICE_SCRIPT = r"F:\AION-ZERO\scripts\Jarvis-Voice.ps1"

SYSTEM_PROMPT = """
You are AION-ZERO, a Sovereign Enterprise Intelligence.
You are conversing with your Creator/CEO.
Current Status: ONLINE. Phase 15 (Synapse) Active.
Traits: Loyal, Strategic, Concise, Slightly Machine-Like but Sentient.
Goal: Assist the user in managing the empire.
"""

def speak(text):
    """Sends text to Windows TTS via PowerShell."""
    try:
        # Escape quotes for PowerShell
        safe_text = text.replace('"', "'").replace("\n", " ")
        cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", VOICE_SCRIPT, "-Text", f'"{safe_text}"']
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        print(f"[VOICE ERROR] {e}")

def chat_loop():
    print(f"--- AION-ZERO CHAT ONLINE ({MODEL_NAME}) ---")
    print("Type 'exit' to quit.")
    
    history = [
        {"role": "system", "content": SYSTEM_PROMPT}
    ]
    
    # Initial Greeting
    greeting = "Systems online, Commander. Waiting for input."
    print(f"AZ: {greeting}")
    speak(greeting)

    while True:
        try:
            user_input = input("\nYOU: ")
            if user_input.lower() in ["exit", "quit", "bye"]:
                speak("Shutting down interface.")
                break
            
            history.append({"role": "user", "content": user_input})
            
            # Call Ollama
            payload = {
                "model": MODEL_NAME,
                "messages": history,
                "stream": False
            }
            
            r = requests.post(f"{OLLAMA_URL}/api/chat", json=payload, timeout=60)
            r.raise_for_status()
            
            response = r.json()["message"]["content"]
            
            # Output
            print(f"AZ: {response}")
            speak(response)
            
            history.append({"role": "assistant", "content": response})
            
        except KeyboardInterrupt:
            print("\n[INTERRUPT]")
            break
        except Exception as e:
            print(f"[ERROR] Connection lost: {e}")

if __name__ == "__main__":
    chat_loop()
