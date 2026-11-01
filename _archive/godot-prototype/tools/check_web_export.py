#!/usr/bin/env python3
"""Static Web/PWA build sanity gate; browser offline E2E remains a separate QA step."""
import json
import sys
from pathlib import Path


def check(web_dir: Path):
    expected = (
        "index.html", "index.js", "index.wasm", "index.pck", "index.service.worker.js",
        "index.offline.html", "index.manifest.json", "index.icon.png", "index.png",
        "index.apple-touch-icon.png", "index.audio.worklet.js", "index.audio.position.worklet.js",
        "index.144x144.png", "index.180x180.png", "index.512x512.png",
    )
    missing = [name for name in expected if not (web_dir / name).is_file()]
    if missing:
        raise ValueError("Missing web export files: " + ", ".join(missing))
    html = (web_dir / "index.html").read_text(encoding="utf-8")
    if "navigator.serviceWorker.register" not in html or "window.rhythmOfflineReady" not in html:
        raise ValueError("Offline bootstrap did not land in generated HTML head")
    for filename in ("index.wasm", "index.pck", "index.manifest.json", "index.512x512.png"):
        if filename not in html:
            raise ValueError("Offline bootstrap does not pre-cache " + filename)
    worker = (web_dir / "index.service.worker.js").read_text(encoding="utf-8")
    if "CACHE_PREFIX" not in worker or "CACHEABLE_FILES" not in worker:
        raise ValueError("Godot-generated service worker missing expected cache contract")
    manifest = json.loads((web_dir / "index.manifest.json").read_text(encoding="utf-8"))
    if manifest.get("display") != "standalone" or not manifest.get("icons"):
        raise ValueError("PWA manifest missing standalone display or icons")
    return len(expected)


if __name__ == "__main__":
    try:
        n = check(Path(sys.argv[1]) if len(sys.argv) > 1 else Path("build/web"))
        print(f"RhythmWebExportStatic: PASS ({n} required files)")
    except (ValueError, OSError) as exc:
        print("RhythmWebExportStatic: FAIL:", exc, file=sys.stderr)
        sys.exit(1)
