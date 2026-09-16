#!/usr/bin/env python3
"""Pre-generate American English audio with macOS `say` (Samantha / Ava)."""

from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "NumSense" / "Content" / "catalog.json"
AUDIO = ROOT / "NumSense" / "Audio"


def pick_voice() -> str:
    out = subprocess.check_output(["say", "-v", "?"], text=True)
    preferred = ["Ava", "Samantha", "Allison", "Susan", "Tom", "Alex"]
    available = []
    for line in out.splitlines():
        name = line.split()[0]
        if "en_US" in line or "en_us" in line:
            available.append(name)
    for name in preferred:
        if name in available:
            return name
    return "Samantha"


def main() -> None:
    AUDIO.mkdir(parents=True, exist_ok=True)
    voice = pick_voice()
    print(f"voice={voice}")
    items = json.loads(CATALOG.read_text())["items"]
    for i, item in enumerate(items, 1):
        dest = AUDIO / item["audioFile"]
        if dest.exists() and dest.stat().st_size > 1000:
            continue
        with tempfile.TemporaryDirectory() as tmp:
            aiff = Path(tmp) / "clip.aiff"
            subprocess.check_call(
                ["say", "-v", voice, "-r", "175", "-o", str(aiff), item["spokenText"]]
            )
            subprocess.check_call(
                ["afconvert", "-f", "m4af", "-d", "aac", str(aiff), str(dest)]
            )
        if i % 20 == 0 or i == len(items):
            print(f"{i}/{len(items)} {dest.name}")
    print("done", AUDIO)


if __name__ == "__main__":
    main()
