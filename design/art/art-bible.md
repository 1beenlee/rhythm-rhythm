# Kitchen Art Bible — v0.1 (Pre-production draft)

**Status:** production direction drafted from 640×360/30fps owner reference; final sprite art not yet produced or approved. This is not a claim of a finished asset pack.

## Composition and visual identity
- One expressive rear/three-quarter-view chef dominates the kitchen center. Two orange/yellow catch bowls are the focal action surface; readable ingredient flight paths surround, never cover, the catch target.
- Distinct spatial layers: exterior/sky behind left window; tiled kitchen wall and shelves; sink and cat; central player; bowls/foremost utensils; refrigerator and magnets at right; discrete text/HUD above as a separate render/UI layer.
- Reference colors to match by curated sampling during asset production: warm off-white/cream tiles, honey yellow, sky blue/teal, tomato red/orange, leafy green, muted chocolate outlines. Preserve consistent line weight and facial/hair anatomy across states.
- Multiple stage treatments in the source: bright daytime, green-tinted, near-white monochrome silhouettes, and marine/underwater dream scene. Treat these as controlled background/lighting scene states with legible gameplay silhouettes, not indiscriminate fullscreen filters.

## Sprite production requirements
- Create actual layered source illustration and exported **transparent PNG/WebP** sprites. Code-drawn circles/rectangles are not acceptable substitutes for chef, vegetables, props or cats.
- Reference 640×360 pixels is *not* a source-resolution target. Author export resolution appropriate to a logical 1280×720 composition and desktop high-DPI; use source illustrations or clean large sheets, not cropped reference thumbnails enlarged.
- Keep pivots and registration identical across animation frames, particularly wrists, fingers, shoulders, bowls and the catch point. Crop with trim metadata rather than changing origin unpredictably.
- Check premultiplied alpha and transparent fringe on both near-white and dark backgrounds. Keep editable source and asset manifest with dimensions, revisions, provenance and sign-off.
- No words, buttons, judgement UI or controller labels baked into background images. Render HUD/text independently in a font with guaranteed Japanese/Korean/Latin glyph coverage.
- For nonstandard aspect ratios, reframe the stage and preserve character proportions: no scale-to-fill distortion. The key catch point must remain visible.

## Required motion states
1. Chef: idle sway/breathing; attention/anticipation; left/right ingredient tracking (only when observable); catch with independent arm/hand + hair follow-through; recovery; miss reaction; optional section-specific expressive pose.
2. Vegetables: per-type flight, scale/rotation where observed, catch impact and removal; fast sequence must read as distinct discrete events.
3. Cat: attentive idle, blink, success/miss reaction — match source footage rather than playing arbitrary particles.
4. Kitchen props: steady environmental motion and occasional section transition. Separate environmental ambience from gameplay readability.
5. Results: distinct result scene art, not an enlarged number or plain black placeholder.

## Motion rules
All cue/anticipation/hit/recovery frames are time-indexed against a **single beat chart**; no frame-count judgement and no pseudo-motion consisting only of camera shake/particle spam. Pose changes must make the action unambiguous in silhouette.

## Proposed export contract (verify in M1 asset acceptance)
- `assets/source/` editable artwork; `assets/sprites/` generated sprite sheets and frame metadata; `assets/backgrounds/` separate foreground/middle/background.
- Each production asset has stable ID, transparent/premultiplied-alpha test, dimensions, pixel density, animation-state list, origin, and a recorded reviewer.
- Minimal M1 review set: composed kitchen scene with pose comparison; ingredient + hands pose sheet; bright/green/monochrome/marine treatment studies. **All are pending production.**

## Primary reference
`docs/research/kitchen-benchmark-m1.md` (user-provided video / audio). Older Godot art and v3 image mentions remain historical references, not assumed accepted source art.
