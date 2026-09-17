#!/usr/bin/env python3
"""Pre-generate American English audio with ElevenLabs (build-time only).

Requires ELEVENLABS_API_KEY in the environment or a repo-root .env file.
Outputs AAC .m4a files named by catalog audioFile fields.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "NumSense" / "Content" / "catalog.json"
AUDIO = ROOT / "NumSense" / "Audio"
CONFIG = Path(__file__).resolve().parent / "audio_config.json"
MANIFEST = AUDIO / "manifest.json"
API_BASE = "https://api.elevenlabs.io/v1"


def load_dotenv() -> None:
    env_path = ROOT / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip("'").strip('"')
        if key and key not in os.environ:
            os.environ[key] = value


def api_key() -> str:
    load_dotenv()
    key = os.environ.get("ELEVENLABS_API_KEY") or os.environ.get("ELEVEN_API_KEY")
    if not key:
        raise SystemExit(
            "Missing ELEVENLABS_API_KEY. Set it in the environment or create "
            f"{ROOT / '.env'} with ELEVENLABS_API_KEY=..."
        )
    return key


def load_config() -> dict:
    return json.loads(CONFIG.read_text())


def synthesize(text: str, cfg: dict, key: str) -> bytes:
    voice_id = cfg["voiceId"]
    output_format = cfg.get("outputFormat", "mp3_44100_128")
    url = f"{API_BASE}/text-to-speech/{voice_id}?output_format={output_format}"
    body = {
        "text": text,
        "model_id": cfg["model"],
        "apply_text_normalization": cfg.get("applyTextNormalization", "off"),
        "voice_settings": {
            "stability": cfg.get("stability", 0.5),
            "similarity_boost": cfg.get("similarityBoost", 0.75),
            "style": cfg.get("style", 0.0),
            "use_speaker_boost": cfg.get("useSpeakerBoost", True),
            "speed": cfg.get("speakingRate", 1.0),
        },
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "xi-api-key": key,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
        },
        method="POST",
    )
    last_err: Exception | None = None
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return resp.read()
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", errors="replace")
            last_err = RuntimeError(f"HTTP {e.code}: {detail}")
            # Rate limit / transient
            if e.code in {429, 500, 502, 503, 504}:
                time.sleep(2 ** attempt)
                continue
            raise last_err from e
        except urllib.error.URLError as e:
            last_err = e
            time.sleep(2 ** attempt)
    raise RuntimeError(f"ElevenLabs request failed after retries: {last_err}")


def mp3_to_m4a(mp3: Path, m4a: Path) -> None:
    subprocess.check_call(
        ["afconvert", "-f", "m4af", "-d", "aac", str(mp3), str(m4a)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate even when destination files already exist.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Only generate the first N items (for smoke tests).",
    )
    args = parser.parse_args()

    key = api_key()
    cfg = load_config()
    AUDIO.mkdir(parents=True, exist_ok=True)
    items = json.loads(CATALOG.read_text())["items"]
    if args.limit > 0:
        items = items[: args.limit]

    print(
        f"vendor=elevenlabs voice={cfg.get('voiceName')} ({cfg['voiceId']}) "
        f"model={cfg['model']} items={len(items)} force={args.force}"
    )

    generated = 0
    skipped = 0
    for i, item in enumerate(items, 1):
        dest = AUDIO / item["audioFile"]
        if dest.exists() and dest.stat().st_size > 1000 and not args.force:
            skipped += 1
            continue

        spoken = item["spokenText"]
        mp3_bytes = synthesize(spoken, cfg, key)
        with tempfile.TemporaryDirectory() as tmp:
            mp3 = Path(tmp) / "clip.mp3"
            mp3.write_bytes(mp3_bytes)
            tmp_out = Path(tmp) / "clip.m4a"
            mp3_to_m4a(mp3, tmp_out)
            tmp_out.replace(dest)

        generated += 1
        if i % 10 == 0 or i == len(items):
            print(f"{i}/{len(items)} {dest.name} ({dest.stat().st_size} bytes)")
        # Be polite to free-tier rate limits.
        time.sleep(0.15)

    manifest = {
        "vendor": cfg["vendor"],
        "voiceId": cfg["voiceId"],
        "voiceName": cfg.get("voiceName"),
        "model": cfg["model"],
        "speakingRate": cfg.get("speakingRate", 1.0),
        "stability": cfg.get("stability"),
        "similarityBoost": cfg.get("similarityBoost"),
        "style": cfg.get("style"),
        "applyTextNormalization": cfg.get("applyTextNormalization", "off"),
        "itemCount": len(json.loads(CATALOG.read_text())["items"]),
        "generatedThisRun": generated,
        "skippedThisRun": skipped,
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"done generated={generated} skipped={skipped} -> {AUDIO}")
    print(f"manifest {MANIFEST}")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
