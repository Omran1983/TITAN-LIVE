import os
import re
import json
import time
import uuid
import argparse
from typing import Dict, Any, List, Optional

import requests

# Optional offline transcription
USE_WHISPER = False
try:
    from faster_whisper import WhisperModel
    USE_WHISPER = True
except Exception:
    USE_WHISPER = False

# Optional mic recording
USE_SOUNDDEVICE = False
try:
    import sounddevice as sd
    import numpy as np
    import soundfile as sf
    USE_SOUNDDEVICE = True
except Exception:
    USE_SOUNDDEVICE = False


def compile_command(text: str, origin: str, requested_by: str) -> Dict[str, Any]:
    """
    Very practical v1 compiler:
    - detects target keywords: doctor/inspector/verifier
    - extracts priority hints: p0/p1/p2/p3
    - sets authority by intent keywords (safe default L1)
    """
    t = text.strip()
    lower = t.lower()

    targets = []
    if "doctor" in lower: targets.append("Doctor")
    if "inspector" in lower: targets.append("Inspector")
    if "verifier" in lower or "verify" in lower: targets.append("Verifier")
    if not targets:
        # default: planner style routing
        targets = ["Doctor"]

    # Priority
    priority = 2
    m = re.search(r"\b(p0|p1|p2|p3)\b", lower)
    if m:
        priority = {"p0":0,"p1":1,"p2":2,"p3":3}[m.group(1)]

    # Intent heuristic
    intent = "execute"
    if any(k in lower for k in ["fix", "bug", "error", "404", "crash"]): intent = "bugfix"
    if any(k in lower for k in ["deploy", "release"]): intent = "deploy"
    if any(k in lower for k in ["report", "summary", "briefing"]): intent = "report"

    # Authority gating heuristic (you can refine)
    authority = "L1"
    if intent in ("deploy",):
        authority = "L3"
    if any(k in lower for k in ["change pricing", "legal", "compliance rules"]):
        authority = "L4"
    if intent == "bugfix":
        authority = "L2"  # safe assumption: bugfix might touch config/routes

    title = (t[:90] + "...") if len(t) > 90 else t

    cmd = {
        "origin": origin,
        "requested_by": requested_by,
        "title": title,
        "intent": intent,
        "objective": t,
        "targets": targets,
        "constraints": ["no behavior change unless explicitly requested"],
        "inputs": {},
        "definition_of_done": ["human_summary produced", "events logged"],
        "notify": ["dashboard"],
        "authority_required": authority,
        "priority": priority
    }
    return cmd


def record_audio_to_wav(path: str, seconds: int = 8, samplerate: int = 16000):
    if not USE_SOUNDDEVICE:
        raise RuntimeError("sounddevice not installed. pip install sounddevice soundfile numpy")
    print(f"Recording {seconds}s... Speak now.")
    audio = sd.rec(int(seconds * samplerate), samplerate=samplerate, channels=1, dtype="float32")
    sd.wait()
    sf.write(path, audio, samplerate)
    print("Saved:", path)


def transcribe_wav(path: str, model_size: str = "base") -> str:
    if not USE_WHISPER:
        raise RuntimeError("faster-whisper not installed. pip install faster-whisper")
    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    segments, info = model.transcribe(path, beam_size=5)
    text = " ".join([seg.text.strip() for seg in segments]).strip()
    return text


def submit_command(control_plane_url: str, token: str, cmd: dict) -> dict:
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    r = requests.post(f"{control_plane_url}/v1/commands", headers=headers, data=json.dumps(cmd), timeout=15)
    if r.status_code >= 300:
        raise RuntimeError(f"Submit failed: {r.status_code} {r.text}")
    return r.json()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--control_plane_url", default=os.environ.get("CONTROL_PLANE_URL", "http://localhost:8010"))
    ap.add_argument("--token", default=os.environ.get("CONTROL_PLANE_TOKEN", ""))
    ap.add_argument("--origin", default="laptop")
    ap.add_argument("--requested_by", default="founder")
    ap.add_argument("--mode", choices=["voice","text"], default="text")
    ap.add_argument("--wav", default="voice_cmd.wav")
    ap.add_argument("--seconds", type=int, default=8)
    ap.add_argument("--whisper_model", default="base")
    args = ap.parse_args()

    if args.mode == "voice":
        record_audio_to_wav(args.wav, seconds=args.seconds)
        transcript = transcribe_wav(args.wav, model_size=args.whisper_model)
        print("Transcript:", transcript)
        if not transcript:
            raise RuntimeError("Empty transcript.")
    else:
        transcript = input("Type your command: ").strip()
        if not transcript:
            raise RuntimeError("Empty input.")

    cmd = compile_command(transcript, origin=args.origin, requested_by=args.requested_by)
    print("Compiled command JSON:", json.dumps(cmd, indent=2))

    resp = submit_command(args.control_plane_url, args.token, cmd)
    command = resp.get("command", {})
    print("\nQueued:", command.get("command_id"), "| state:", command.get("state"))
    print("Title:", command.get("title"))

if __name__ == "__main__":
    main()
