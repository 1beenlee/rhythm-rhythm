# Build and offline acceptance

1. Install **Godot 4.7.2-stable** editor and matching 4.7.2 export templates from the official release. On Windows, extract and run; system installation is not required.
2. `godot --headless --path . --import` then `godot --headless --path . --script tests/godot_judge_test.gd` (or invoke the editor executable directly).
3. `mkdir -p build/web build/windows` and export:
   - `godot --headless --path . --export-release "Web" build/web/index.html`
   - `godot --headless --path . --export-release "Windows Desktop" build/windows/RhythmRhythm.exe`
4. Web preset: Compatibility renderer, single-threaded (`variant/thread_support=false`), PWA enabled, explicit 144/180/512px local PNGs, `*.json` included. Godot generates its own manifest/service worker; do not hand-maintain a competing worker. Our `html/head_include` registers that worker unconditionally on first load and caches the generated WASM/PCK and PWA icons. `window.rhythmOfflineReady === true` (and `document.documentElement.dataset.rhythmOffline === "ready"`) indicates that all required files were found in the browser cache. Reloading while offline must be tested separately; readiness is not itself proof of offline playback.
5. Serve `build/web/` on a localhost HTTP server for testing (file:// is NOT an equivalent test), install PWA from HTTPS origin for public/mobile deployment. Wait for `window.rhythmOfflineReady === true`, then confirm Cache Storage includes WASM/PCK/JS, manifest and icons; trigger first-load audio unlock with a tap.
6. In Chrome DevTools: Application → Service Workers/Cache Storage to inspect, Network → Offline, *close and relaunch* installed PWA, play 3 games, persist score. Test mobile browser separately. Browser storage eviction/clearing can lose offline cache and settings.
7. Windows EXE (and adjacent PCK if exported separately) must start in airplane mode and keep records across restart. Do not claim a Godot EXE exists merely because preset was written.
8. **Public GitHub Pages deployment requires separate user approval.** The build and local file paths are not public URLs.
